// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IVrfManager} from "../interface/IVrfManager.sol";
import {IMockVrfOracle} from "../interface/IMockVrfOracle.sol";

/**
 * @title VrfManager
 * @dev VRF管理合约 - 使用最小代理模式，不需要可升级功能
 * @notice 每个代理实例都是独立的，通过工厂创建新版本来实现"升级"
 */
contract VrfManager is IVrfManager {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    struct RequestStatus {
        bool fulfilled;
        uint256[] randomWords;
        uint256 timestamp;
        uint256 blockNumber;
        uint256 oracleRequestId;
    }

    // 状态变量
    uint256[] public requestIds;
    uint256 public lastRequestId;
    address public vrfOracleAddress;
    address public oraclePublicKey;
    uint256 public signatureExpiry = 300; // 5分钟

    mapping(uint256 => RequestStatus) public requestMapping;
    mapping(bytes32 => bool) public usedSignatures;

    // 初始化标志（防止重复初始化）
    bool private _initialized;

    modifier onlyVRFOracle() {
        require(msg.sender == vrfOracleAddress, "Only vrfOracle can call this function");
        _;
    }

    modifier onlyOnce() {
        require(!_initialized, "Already initialized");
        _;
    }

    constructor() {
        // 构造函数留空，初始化通过initialize函数完成
    }

    /**
     * @dev 初始化函数 - 替代可升级合约的initializer
     * @param initialOwner 合约所有者
     * @param _oracleAddress Oracle合约地址
     * @param _oraclePublicKey 签名Oracle公钥地址
     */
    function initialize(address initialOwner, address _oracleAddress, address _oraclePublicKey) external onlyOnce {
        require(initialOwner != address(0), "Invalid owner");
        require(_oracleAddress != address(0), "Invalid oracle address");
        require(_oraclePublicKey != address(0), "Invalid oracle public key");

        // 设置Oracle配置
        vrfOracleAddress = _oracleAddress;
        oraclePublicKey = _oraclePublicKey;

        // 标记为已初始化
        _initialized = true;

        emit OraclePublicKeyUpdated(address(0), _oraclePublicKey);
    }

    /**
     * @dev 检查是否已初始化
     */
    function isInitialized() external view returns (bool) {
        return _initialized;
    }

    /**
     * @dev 请求随机数
     */
    function requestRandomWords(uint256 _requestId, uint256 _numWords) external {
        require(_initialized, "Contract not initialized");

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
     */
    function fulfillRandomWordsWithSignature(
        uint256 _requestId,
        uint256[] memory _randomWords,
        uint256 timestamp,
        bytes memory signature
    ) external {
        require(_initialized, "Contract not initialized");
        require(requestMapping[_requestId].timestamp > 0, "Request does not exist");
        require(!requestMapping[_requestId].fulfilled, "Request already fulfilled");
        require(block.timestamp - timestamp <= signatureExpiry, "Signature expired");

        // 构造消息哈希
        bytes32 messageHash = _buildMessageHash(_requestId, _randomWords, timestamp);
        require(!usedSignatures[messageHash], "Signature already used");

        // 验证签名
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address recoveredSigner = ECDSA.recover(ethSignedMessageHash, signature);
        require(recoveredSigner == oraclePublicKey, "Invalid signature");

        // 更新状态
        usedSignatures[messageHash] = true;
        requestMapping[_requestId].fulfilled = true;
        requestMapping[_requestId].randomWords = _randomWords;

        emit SignatureVerified(_requestId, recoveredSigner);
        emit FillRandomWords(_requestId, _randomWords);
    }

    /**
     * @dev 构造消息哈希
     */
    function _buildMessageHash(uint256 _requestId, uint256[] memory _randomWords, uint256 timestamp)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(address(this), _requestId, _randomWords, timestamp, block.chainid));
    }

    /**
     * @dev 验证签名
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
     * @dev 获取请求详情
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

    /**
     * @dev 管理函数 - 设置VRF Oracle地址
     */
    function setVRFOracle(address _oracleAddress) external {
        require(_oracleAddress != address(0), "Invalid oracle address");
        vrfOracleAddress = _oracleAddress;
    }

    /**
     * @dev 设置Oracle公钥
     */
    function setOraclePublicKey(address _publicKey) external {
        require(_publicKey != address(0), "Invalid public key");
        address oldKey = oraclePublicKey;
        oraclePublicKey = _publicKey;
        emit OraclePublicKeyUpdated(oldKey, _publicKey);
    }

    /**
     * @dev 设置签名有效期
     */
    function setSignatureExpiry(uint256 _expiry) external {
        require(_expiry > 0, "Invalid expiry time");
        signatureExpiry = _expiry;
        emit SignatureExpiryUpdated(_expiry);
    }

    /**
     * @dev 获取消息哈希
     */
    function getMessageHash(uint256 _requestId, uint256[] memory _randomWords, uint256 timestamp)
        external
        view
        returns (bytes32)
    {
        return _buildMessageHash(_requestId, _randomWords, timestamp);
    }
}
