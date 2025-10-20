// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title A simple Raffle Contract
 * @author Sandwich
 * @notice This contract is for creating a simple raffle system.
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();

    address payable[] private s_players;
    //@dev the duration of the lottery in seconds
    uint256 private immutable i_interval;
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimeStamp;

    /* Events */
    event RaffleEnter(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    // Logic for picking a winner
    // 1. get a random number
    // 2. use that random number to pick a winner from s_players
    // 3. be automatically called
    function pickWinner() external {
        //check to see if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
        //get a random number
        //1. Request RNG
        //2. Get RNG
        
    }

    function enterRaffle() external payable {
        // Logic for entering the raffle
        // require(msg.value >= i_entranceFee, "Not enough ETH to enter the raffle");
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
