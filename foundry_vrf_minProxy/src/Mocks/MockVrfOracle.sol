// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IVrfManager} from "../interface/IVrfManager.sol";
import {IMockVrfOracle} from "../interface/IMockVrfOracle.sol";

/**
 * @title MockVrfOracle
 * @dev 模拟Oracle，接收VrfManager的请求，生成随机数并回调验证
 */
contract MockVrfOracle is Ownable, IMockVrfOracle {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    struct RandomRequest {
        uint256 requestId;
        address vrfManager;
        uint256 numWords;
        uint256 timestamp;
        bool fulfilled;
        bool callbackSent;
    }

    mapping(uint256 => RandomRequest) public requests;
    mapping(address => uint256[]) public vrfManagerRequests; // 每个VrfManager的请求列表
    uint256 public nextRequestId = 1;

    // Oracle私钥持有者地址（在实际应用中应该保密）
    address public oracleSigner;

    // Oracle操作者，可以触发fulfillment
    address public oracleOperator;

    event RandomRequested(uint256 indexed requestId, address indexed vrfManager, uint256 numWords);
    event RandomFulfilled(uint256 indexed requestId, uint256[] randomWords);
    event CallbackSent(uint256 indexed requestId, bool success);

    constructor(address _oracleSigner) Ownable(msg.sender) {
        oracleSigner = _oracleSigner;
        oracleOperator = msg.sender;
    }

    modifier onlyOperator() {
        require(msg.sender == oracleOperator, "Only oracle operator");
        _;
    }

    /**
     * @dev VrfManager调用此函数请求随机数
     */
    function requestRandomWords(uint256 numWords) external returns (uint256 requestId) {
        requestId = nextRequestId++;

        requests[requestId] = RandomRequest({
            requestId: requestId,
            vrfManager: msg.sender,
            numWords: numWords,
            timestamp: block.timestamp,
            fulfilled: false,
            callbackSent: false
        });

        vrfManagerRequests[msg.sender].push(requestId);

        emit RandomRequested(requestId, msg.sender, numWords);
        return requestId;
    }

    /**
     * @dev 生成随机数（模拟链下生成过程）
     */
    function generateRandomWords(uint256 requestId, uint256 seed) public view returns (uint256[] memory) {
        RandomRequest memory request = requests[requestId];
        require(request.requestId != 0, "Request does not exist");

        uint256[] memory randomWords = new uint256[](request.numWords);

        for (uint256 i = 0; i < request.numWords; i++) {
            randomWords[i] = uint256(
                keccak256(abi.encodePacked(seed, requestId, i, block.prevrandao, block.timestamp, request.vrfManager))
            );
        }

        return randomWords;
    }

    /**
     * @dev Oracle操作员使用预先生成的签名来完成请求
     * @param requestId Oracle请求ID
     * @param seed 随机种子
     * @param signature 链下生成的ECDSA签名
     */
    function fulfillRequestWithSignature(uint256 requestId, uint256 seed, bytes memory signature)
        external
        onlyOperator
    {
        RandomRequest storage request = requests[requestId];
        require(request.requestId != 0, "Request does not exist");
        require(!request.fulfilled, "Request already fulfilled");

        // 1. 生成随机数
        uint256[] memory randomWords = generateRandomWords(requestId, seed);

        // 2. 创建时间戳
        uint256 timestamp = block.timestamp;

        // 3. 调用VrfManager的签名验证函数
        try IVrfManager(request.vrfManager).fulfillRandomWordsWithSignature(
            requestId, randomWords, timestamp, signature
        ) {
            request.fulfilled = true;
            request.callbackSent = true;
            emit RandomFulfilled(requestId, randomWords);
            emit CallbackSent(requestId, true);
        } catch Error(string memory reason) {
            emit CallbackSent(requestId, false);
            revert(string(abi.encodePacked("VrfManager callback failed: ", reason)));
        } catch {
            emit CallbackSent(requestId, false);
            revert("VrfManager callback failed with unknown error");
        }
    }

    /**
     * @dev 获取需要签名的消息哈希（供链下签名使用）
     * @param vrfManager VrfManager合约地址
     * @param requestId 请求ID
     * @param randomWords 随机数数组
     * @param timestamp 时间戳
     * @return messageHash 原始消息哈希
     * @return ethSignedMessageHash 以太坊格式的签名消息哈希
     */
    function getMessageToSign(address vrfManager, uint256 requestId, uint256[] memory randomWords, uint256 timestamp)
        public
        view
        returns (bytes32 messageHash, bytes32 ethSignedMessageHash)
    {
        // 构造与VrfManager相同的消息哈希
        messageHash = keccak256(abi.encodePacked(vrfManager, requestId, randomWords, timestamp, block.chainid));

        // 转换为以太坊签名消息哈希
        ethSignedMessageHash = messageHash.toEthSignedMessageHash();

        return (messageHash, ethSignedMessageHash);
    }

    /**
     * @dev 批量处理多个请求
     */
    function fulfillMultipleRequests(
        uint256[] calldata requestIds,
        uint256[] calldata seeds,
        bytes[] calldata signatures
    ) external onlyOperator {
        require(requestIds.length == seeds.length && seeds.length == signatures.length, "Arrays length mismatch");

        for (uint256 i = 0; i < requestIds.length; i++) {
            if (!requests[requestIds[i]].fulfilled) {
                try this.fulfillRequestWithSignature(requestIds[i], seeds[i], signatures[i]) {
                    // Success handled in the called function
                } catch {
                    // Continue with next request even if one fails
                    continue;
                }
            }
        }
    }

    /**
     * @dev 模拟完整的链下工作流程
     */
    function simulateOffchainWork(uint256 requestId, uint256 seed)
        external
        view
        returns (uint256[] memory randomWords, uint256 timestamp, bytes32 messageHash, bytes32 ethSignedMessageHash)
    {
        RandomRequest memory request = requests[requestId];
        require(request.requestId != 0, "Request does not exist");

        // 1. 生成随机数
        randomWords = generateRandomWords(requestId, seed);

        // 2. 生成时间戳
        timestamp = block.timestamp;

        // 3. 构造消息哈希
        (messageHash, ethSignedMessageHash) = getMessageToSign(request.vrfManager, requestId, randomWords, timestamp);

        return (randomWords, timestamp, messageHash, ethSignedMessageHash);
    }

    /**
     * @dev 更新Oracle操作员
     */
    function setOracleOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "Invalid operator address");
        oracleOperator = newOperator;
    }

    /**
     * @dev 更新Oracle签名者地址
     */
    function updateOracleSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "Invalid signer address");
        oracleSigner = newSigner;
    }

    /**
     * @dev 获取请求信息
     */
    function getRequest(uint256 requestId) external view returns (RandomRequest memory) {
        return requests[requestId];
    }
}
