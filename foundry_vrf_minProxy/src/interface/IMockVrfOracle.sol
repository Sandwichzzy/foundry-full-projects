// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

interface IMockVrfOracle {
    function requestRandomWords(uint256 numWords) external returns (uint256 requestId);
}
