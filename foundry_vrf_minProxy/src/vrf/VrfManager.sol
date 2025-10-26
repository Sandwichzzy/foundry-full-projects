// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IVrfManager} from "../interface/IVrfManager.sol";
import {IMockVrfOracle} from "../interface/IMockVrfOracle.sol";

contract VrfManager is IVrfManager, Initializable, OwnableUpgradeable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    struct RequestStatus {
        bool fulfilled;
        uint256[] randomWords;
        uint256 timestamp;
        uint256 blockNumber;
        uint256 oracleRequestId; // Oracle返回的请求ID
    }

    uint256[] public requestIds;
    uint256 public lastRequestId;
    address public vrfOracleAddress;
    address public oraclePublicKey; // Oracle的公钥地址
    uint256 public signatureExpiry = 300; // 签名有效期（秒）

    mapping(uint256 => RequestStatus) public requestMapping;
    mapping(bytes32 => bool) public usedSignatures; // 防止签名重放攻击
    uint256[100] private slot;

    constructor() {
        _disableInitializers();
    }

    modifier onlyVRFOracle() {
        require(msg.sender == vrfOracleAddress, "Only vrfOracle can call this function");
        _;
    }

    function initialize(address initialOwner, address _oracleAddress) public initializer {
        __Ownable_init(initialOwner);
        vrfOracleAddress = _oracleAddress;
        oraclePublicKey = _oracleAddress; // 默认使用Oracle地址作为公钥
    }

    /**
     * @dev 请求随机数（向Oracle发起请求）
     */
    function requestRandomWords(uint256 _requestId, uint256 _numWords) public onlyOwner {
        // 向Oracle发起请求
        uint256 oracleRequestId = IMockVrfOracle(vrfOracleAddress).requestRandomWords(_numWords);

        requestMapping[_requestId] = RequestStatus({
            fulfilled: false,
            randomWords: new uint256[](0),
            timestamp: block.timestamp,
            blockNumber: block.number,
            oracleRequestId: oracleRequestId
        });
        requestIds.push(_requestId);
        lastRequestId = _requestId;

        emit OracleRequestSent(_requestId, oracleRequestId, _numWords);
    }

    /**
     * @dev 使用ECDSA签名验证的随机数提交函数
     * @param _requestId 请求ID
     * @param _randomWords 随机数数组
     * @param timestamp 时间戳
     * @param signature ECDSA签名
     */
    function fulfillRandomWordsWithSignature(
        uint256 _requestId,
        uint256[] memory _randomWords,
        uint256 timestamp,
        bytes memory signature
    ) external {
        // 验证请求是否存在且未完成
        require(requestMapping[_requestId].timestamp > 0, "Request does not exist");
        require(!requestMapping[_requestId].fulfilled, "Request already fulfilled");

        // 验证时间戳有效性
        require(block.timestamp - timestamp <= signatureExpiry, "Signature expired");

        // 构造消息哈希
        bytes32 messageHash = _buildMessageHash(_requestId, _randomWords, timestamp);

        // 验证签名未被使用过
        require(!usedSignatures[messageHash], "Signature already used");

        // 验证签名
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address recoveredSigner = ECDSA.recover(ethSignedMessageHash, signature);
        require(recoveredSigner == oraclePublicKey, "Invalid signature");

        // 标记签名已使用
        usedSignatures[messageHash] = true;

        // 更新请求状态
        requestMapping[_requestId].fulfilled = true;
        requestMapping[_requestId].randomWords = _randomWords;

        emit SignatureVerified(_requestId, recoveredSigner);
        emit FillRandomWords(_requestId, _randomWords);
    }

    /**
     * @dev 构造用于签名的消息哈希
     */
    function _buildMessageHash(uint256 _requestId, uint256[] memory _randomWords, uint256 timestamp)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(address(this), _requestId, _randomWords, timestamp, block.chainid));
    }

    /**
     * @dev 验证签名（外部调用，用于测试）
     */
    function verifySignature(
        uint256 _requestId,
        uint256[] memory _randomWords,
        uint256 timestamp,
        bytes memory signature
    ) external view returns (bool, address) {
        bytes32 messageHash = _buildMessageHash(_requestId, _randomWords, timestamp);
        address recoveredSigner = messageHash.toEthSignedMessageHash().recover(signature);
        return (recoveredSigner == oraclePublicKey, recoveredSigner);
    }

    /**
     * @dev 获取请求的详细信息，包括Oracle请求ID
     */
    function getRequestDetails(uint256 _requestId)
        external
        view
        returns (
            bool fulfilled,
            uint256[] memory randomWords,
            uint256 timestamp,
            uint256 blockNumber,
            uint256 oracleRequestId
        )
    {
        RequestStatus memory request = requestMapping[_requestId];
        return (request.fulfilled, request.randomWords, request.timestamp, request.blockNumber, request.oracleRequestId);
    }

    function setVRFOracle(address _oracleAddress) external onlyOwner {
        vrfOracleAddress = _oracleAddress;
    }

    /**
     * @dev 设置Oracle公钥地址
     */
    function setOraclePublicKey(address _publicKey) external onlyOwner {
        require(_publicKey != address(0), "Invalid public key");
        address oldKey = oraclePublicKey;
        oraclePublicKey = _publicKey;
        emit OraclePublicKeyUpdated(oldKey, _publicKey);
    }

    /**
     * @dev 设置签名有效期
     */
    function setSignatureExpiry(uint256 _expiry) external onlyOwner {
        require(_expiry > 0, "Invalid expiry time");
        signatureExpiry = _expiry;
        emit SignatureExpiryUpdated(_expiry);
    }

    /**
     * @dev 获取消息哈希（用于离线签名）
     */
    function getMessageHash(uint256 _requestId, uint256[] memory _randomWords, uint256 timestamp)
        external
        view
        returns (bytes32)
    {
        return _buildMessageHash(_requestId, _randomWords, timestamp);
    }
}
