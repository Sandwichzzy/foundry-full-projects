// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {GamblingGameManager} from "../src/core/GamblingGameManager.sol";
import {LuckDrawManager} from "../src/core/LuckDrawManager.sol";
import {OracleMock} from "../test/mocks/mockOracle.sol";

contract LuckDrawDeployer is Script {
    function run() external {
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        address luckyDrawer = vm.envAddress("LUCKY_DRAWER");
        address gamblingGameManager = vm.envAddress("GAMBLING_GAME_MANAGER");
        vm.startBroadcast(initialOwner);
        // 1. 先部署 OracleMock
        OracleMock oracle = new OracleMock();
        console.log("OracleMock deployed at:", address(oracle));
        // 2. 部署 LuckDrawManager 实现合约
        LuckDrawManager luckDrawManager = new LuckDrawManager();
        console.log("LuckDrawManager implementation deployed at:", address(luckDrawManager));

        // 3. 初始化合约
        luckDrawManager.initialize(initialOwner, luckyDrawer, gamblingGameManager, address(oracle));
        console.log("LuckDrawManager initialized");

        vm.stopBroadcast();

        // 输出部署结果
        console.log("=== Deployment Summary ===");
        console.log("LuckDrawManager:", address(luckDrawManager));
        console.log("OracleMock:", address(oracle));
        console.log("Initial Owner:", initialOwner);
        console.log("Lucky Drawer:", luckyDrawer);
        console.log("GamblingGameManager:", gamblingGameManager);
    }
}
