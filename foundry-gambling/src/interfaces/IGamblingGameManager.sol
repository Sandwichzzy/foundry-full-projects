// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface IGamblingGameManager {
    event GuessBettorCreate(address indexed account, uint256 value, uint8 betType);

    event AllocateReward(address indexed account, uint256 hgmId, uint8 betType, uint256 rewardValue, bool hasReward);

    function setBetteToken(address _betToken, uint256 _betteTokenDecimal) external;

    function createBettor(uint256 _amount, uint8 _betType) external returns (bool);

    function luckyDraw(uint256[3] memory _threeNumbers) external;

    function setGameBlock(uint256 _blocks) external;

    function getBalance() external view returns (uint256);
}
