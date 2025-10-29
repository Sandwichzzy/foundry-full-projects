// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Vm.sol";
import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "../src/utils/EmptyContract.sol";
import "../src/contracts/vrf/TheWeb3VRFManager.sol";
import "../src/contracts/TheWeb3VRFFactory.sol";
import "../src/contracts/bls/BLSApkRegistry.sol";

contract TheWeb3VRFDepolyScript is Script {
    address public proxy;
    EmptyContract public emptyContract;
    BLSApkRegistry public blsApkRegistry;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast();

        // 第一步：使用 OpenZeppelin Foundry Upgrades 部署 EmptyContract 的 UUPS 代理
        console.log("Step 1: Deploying EmptyContract with UUPS proxy...");

        bytes memory emptyInitData = abi.encodeCall(EmptyContract.initialize, deployerAddress);

        proxy = Upgrades.deployUUPSProxy("EmptyContract.sol:EmptyContract", emptyInitData);

        emptyContract = EmptyContract(proxy);
        console.log("EmptyContract UUPS proxy deployed at:", proxy);
        console.log("Testing EmptyContract function:", emptyContract.foo());

        // 第二步：将代理从 EmptyContract 升级到 BLSApkRegistry
        console.log("Step 2: Upgrading EmptyContract to BLSApkRegistry...");

        // 使用 upgradeProxy 进行升级，调用 initializeV2
        Upgrades.upgradeProxy(
            proxy,
            "BLSApkRegistry.sol:BLSApkRegistry",
            abi.encodeCall(BLSApkRegistry.initializeV2, (deployerAddress, deployerAddress, deployerAddress))
        );

        console.log("Successfully upgraded to BLSApkRegistry at:", proxy);

        blsApkRegistry = BLSApkRegistry(proxy);

        // 第三步：部署其他合约
        console.log("Step 3: Deploying other contracts...");

        TheWeb3VRFManager theWeb3VRF = new TheWeb3VRFManager();
        console.log("TheWeb3VRFManager deployed at:", address(theWeb3VRF));

        TheWeb3VRFFactory theweb3VRFFactory = new TheWeb3VRFFactory(address(theWeb3VRF));
        console.log("TheWeb3VRFFactory deployed at:", address(theweb3VRFFactory));

        bytes32 salt = keccak256("project1");
        address proxyTheWeb3Pod = theweb3VRFFactory.createVrfMinProxy(salt, deployerAddress, proxy);
        console.log("TheWeb3Pod proxy deployed at:", proxyTheWeb3Pod);

        console.log("\n=== Deployment Summary ===");
        console.log("UUPS Proxy Address (EmptyContract -> BLSApkRegistry):", proxy);
        console.log("TheWeb3VRFManager:", address(theWeb3VRF));
        console.log("TheWeb3VRFFactory:", address(theweb3VRFFactory));
        console.log("TheWeb3Pod proxy:", proxyTheWeb3Pod);

        // 验证升级是否成功
        console.log("\n=== Verification ===");
        console.log("Proxy owner:", blsApkRegistry.owner());
        console.log("WhitelistManager:", blsApkRegistry.whitelistManager());
        console.log("VrfManagerAddress:", blsApkRegistry.vrfManagerAddress());

        vm.stopBroadcast();
    }
}
