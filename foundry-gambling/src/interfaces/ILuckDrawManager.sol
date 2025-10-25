// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface ILuckDrawManager {
    event RandomNumbersRequested(uint256 requestId);
    event RandomNumbersReceived(uint256[3] numbers);
    event LuckyDrawExecuted(uint256[3] numbers);

    function requestRandomNumbers() external;
    function receiveCallback(bytes memory response) external;
}
