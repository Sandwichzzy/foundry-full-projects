// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script,console} from "forge-std/Script.sol";
import {SWToken} from "../src/SWToken.sol";

contract DeploySWToken is Script {
    SWToken public swToken;

    uint256 public constant INITIAL_SUPPLY = 10000000 ether; // 1 million tokens with 18 decimal places

    function run() external returns (SWToken) {
      vm.startBroadcast();
      swToken = new SWToken(INITIAL_SUPPLY);
      console.log("SWToken deployed to:", address(swToken));
      console.log("Deployment complete.");
      vm.stopBroadcast();
      return swToken;
    }
}
