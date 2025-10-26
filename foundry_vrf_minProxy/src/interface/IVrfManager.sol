// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

interface IVrfManager {
    event FillRandomWords(uint256 requestId, uint256[] randomWords);
    event SignatureVerified(uint256 indexed requestId, address signer);
    event OraclePublicKeyUpdated(address indexed oldKey, address indexed newKey);
    event SignatureExpiryUpdated(uint256 newExpiry);
    event OracleRequestSent(uint256 indexed requestId, uint256 indexed oracleRequestId, uint256 numWords);

    function requestRandomWords(uint256 _requestId, uint256 _numWords) external;
    function fulfillRandomWordsWithSignature(
        uint256 _requestId,
        uint256[] memory _randomWords,
        uint256 timestamp,
        bytes memory signature
    ) external;
    function getRequestDetails(uint256 _requestId)
        external
        view
        returns (
            bool fulfilled,
            uint256[] memory randomWords,
            uint256 timestamp,
            uint256 blockNumber,
            uint256 oracleRequestId
        );
    function setVRFOracle(address _oracleAddress) external;
    function setOraclePublicKey(address _publicKey) external;
    function verifySignature(
        uint256 _requestId,
        uint256[] memory _randomWords,
        uint256 timestamp,
        bytes memory signature
    ) external view returns (bool, address);
}
