// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";

contract FundMeDeploy is Test {
    FundMe public fundMe;
    HelperConfig public helperConfig;

    function setUp() public {
        DeployFundMe deployFundMe = new DeployFundMe();
        (fundMe, helperConfig) = deployFundMe.deployFundMe();
    }

    function testDeployFundMe() public view {
        assertEq(address(fundMe.getPriceFeed()), helperConfig.activeNetworkConfig());
    }
}
