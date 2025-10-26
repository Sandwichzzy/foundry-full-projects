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

    // Oracle签名者地址 - 这应该是拥有私钥的地址，用于签名验证
    address public constant ORACLE_SIGNER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // 测试账户#1

    function run() external {
        address deployer = msg.sender;
        console.log("Deploying with address:", deployer);
        console.log("Oracle signer will be:", ORACLE_SIGNER);

        vm.startBroadcast();

        // 1. 部署MockVrfOracle - 使用ORACLE_SIGNER作为签名者
        mockOracle = new MockVrfOracle(ORACLE_SIGNER);
        console.log("MockVrfOracle deployed at:", address(mockOracle));

        // 2. 设置Oracle操作员为部署者
        mockOracle.setOracleOperator(deployer);
        console.log("Oracle operator set to:", deployer);

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

        // 6. 初始化代理合约 - 注意：现在传递三个参数
        VrfManager proxy = VrfManager(proxyAddress);
        proxy.initialize(deployer, address(mockOracle), ORACLE_SIGNER);

        console.log("Proxy initialized with owner:", deployer);
        console.log("Oracle address set to:", address(mockOracle));
        console.log("Oracle public key set to:", ORACLE_SIGNER);

        // 7. 验证部署
        address[] memory allProxies = proxyFactory.getProxies();
        console.log("Total proxies created:", allProxies.length);

        // 8. 验证初始化状态
        bool isInitialized = proxy.isInitialized();
        console.log("Proxy initialization status:", isInitialized);

        vm.stopBroadcast();
    }

    /**
     * @dev 为新项目创建代理合约
     */
    function createProjectProxyWithOracle(string memory projectName, address projectOwner) external {
        require(address(proxyFactory) != address(0), "Factory not deployed yet");

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

        // 初始化代理合约 - 使用正确的三参数初始化
        VrfManager proxy = VrfManager(proxyAddress);
        proxy.initialize(projectOwner, address(mockOracle), ORACLE_SIGNER);

        console.log("Proxy initialized with owner:", projectOwner);
        console.log("Oracle public key set to:", ORACLE_SIGNER);
        console.log("Proxy address for project:", projectName, "is", proxyAddress);

        vm.stopBroadcast();
    }
}
