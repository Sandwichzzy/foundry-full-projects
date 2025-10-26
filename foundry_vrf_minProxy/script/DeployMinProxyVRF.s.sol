// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {VrfManager} from "../src/vrf/VrfManager.sol";
import {VrfMinProxyFactory} from "../src/VrfMinProxyFactory.sol";
import {MockVrfOracle} from "../src/Mocks/MockVrfOracle.sol";

contract DeployMinProxyVRFScript is Script {
    VrfManager public vrfManagerImplementation;
    VrfMinProxyFactory public proxyFactory;
    MockVrfOracle public mockOracle;

    // Oracle私钥地址（在测试中使用固定地址）
    address public constant ORACLE_SIGNER = 0x6002BaD747AfD5690f543a670f3e3bD30E033084; // Hardhat测试账户#1

    function run() external {
        vm.startBroadcast();

        // 1. 部署MockVrfOracle
        mockOracle = new MockVrfOracle(ORACLE_SIGNER);
        console.log("MockVrfOracle deployed at:", address(mockOracle));

        // 2. 设置Oracle操作员
        mockOracle.setOracleOperator(msg.sender);
        console.log("Oracle operator set to:", msg.sender);

        // 3. 部署VrfManager实现合约
        vrfManagerImplementation = new VrfManager();
        console.log("VrfManager Implementation deployed at:", address(vrfManagerImplementation));

        // 4. 部署VrfMinProxyFactory管理合约
        proxyFactory = new VrfMinProxyFactory(address(vrfManagerImplementation));
        console.log("VrfMinProxyFactory deployed at:", address(proxyFactory));

        // 5. 使用create2创建第一个代理合约示例
        bytes32 salt = keccak256("project1");
        address proxyAddress = proxyFactory.createProxy(salt);
        console.log("First proxy created at:", proxyAddress);

        // 6. 初始化代理合约
        VrfManager proxy = VrfManager(proxyAddress);
        proxy.initialize(msg.sender, address(mockOracle));

        // 7. 设置Oracle公钥（使用ORACLE_SIGNER地址）
        proxy.setOraclePublicKey(ORACLE_SIGNER);
        console.log("Proxy initialized with owner:", msg.sender);
        console.log("Oracle public key set to:", ORACLE_SIGNER);

        // 8. 验证部署
        address[] memory allProxies = proxyFactory.getProxies();
        console.log("Total proxies created:", allProxies.length);

        vm.stopBroadcast();
    }

    /**
     * @dev 为新项目创建代理合约（带签名验证功能）
     */
    function createProjectProxyWithOracle(string memory projectName, address projectOwner) external {
        vm.startBroadcast();

        bytes32 salt = keccak256(abi.encodePacked(projectName));

        // 检查是否已存在
        address predictedAddress = proxyFactory.computeProxyAddress(salt);
        if (predictedAddress.code.length > 0) {
            console.log("Proxy already exists for project:", projectName);
            console.log("Address:", predictedAddress);
            vm.stopBroadcast();
            return;
        }

        // 创建新代理
        address proxyAddress = proxyFactory.createProxy(salt);
        console.log("New proxy created for project:", projectName);
        console.log("Address:", proxyAddress);

        // 初始化代理合约
        VrfManager proxy = VrfManager(proxyAddress);
        proxy.initialize(projectOwner, address(mockOracle));
        proxy.setOraclePublicKey(ORACLE_SIGNER);
        console.log("Proxy initialized with owner:", projectOwner);
        console.log("Oracle configured for signature verification");
        console.log("Proxy address for project:", projectName, "is", proxyAddress);

        vm.stopBroadcast();
    }
}
