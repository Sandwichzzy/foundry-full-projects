// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./IBLSApkRegistry.sol";

interface ITheWeb3VRFManager {
    event RequestSent(uint256 indexed requestId, uint256 numWords, address current);

    event FillRandomWords(uint256 indexed requestId, uint256[] randomWords);

    function requestRandomWords(uint256 requestId, uint256 numWords) external;
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords,
        bytes32 msgHash,
        uint256 referenceBlockNumber,
        IBLSApkRegistry.VrfNoSignerAndSignature memory params
    ) external;

    function getRequestStatus(uint256 requestId) external view returns (bool fulfilled, uint256[] memory randomWords);
}
