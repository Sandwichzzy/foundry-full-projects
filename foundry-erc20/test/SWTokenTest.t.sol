// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {DeploySWToken} from "../script/DeploySWToken.s.sol";
import {SWToken} from "../src/SWToken.sol";
import {Test, console} from "forge-std/Test.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract OurTokenTest is Test {
    uint256 BOB_STARTING_AMOUNT = 100 ether;
    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether; // 1 million tokens with 18 decimal places

    SWToken public swToken;
    DeploySWToken public deployer;
    address public deployerAddress;
    address bob;
    address alice;

    function setUp() public {
        deployer = new DeploySWToken();
        swToken = deployer.run();

        bob = makeAddr("bob");
        alice = makeAddr("alice");

        vm.prank(msg.sender);
        swToken.transfer(bob, BOB_STARTING_AMOUNT);
    }

    function testInitialSupply() public view {
        assertEq(swToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(swToken)).mint(address(this), 1);
    }

    function testAllowances() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice to spend tokens on his behalf

        vm.prank(bob);
        swToken.approve(alice, initialAllowance);
        uint256 transferAmount = 500;

        vm.prank(alice);
        swToken.transferFrom(bob, alice, transferAmount);
        assertEq(swToken.balanceOf(alice), transferAmount);
        assertEq(swToken.balanceOf(bob), BOB_STARTING_AMOUNT - transferAmount);
    }
}
