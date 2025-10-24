// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Script, console} from "forge-std/Script.sol";
import "forge-std/Vm.sol";

import {GamblingGameManager} from "../src/core/GamblingGameManager.sol";
import {EmptyContract} from "./EmptyContract.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract GamblingERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

contract GamblingGameDeployer is Script {
    GamblingERC20 public betteToken;
    // 空合约，用作代理的初始实现
    EmptyContract public emptyContract;
    // 代理管理员合约，负责管理代理的升级
    ProxyAdmin public proxyAdmin;
    // 代理合约地址（用户实际交互的地址）
    GamblingGameManager public gamblingGameManagerProxy;
    // 实现合约地址（包含实际逻辑的合约）
    GamblingGameManager public gamblingGameManagerImplementation;

    function run() external {
        address deployerAddr = 0x6002BaD747AfD5690f543a670f3e3bD30E033084;
        vm.startBroadcast(deployerAddr);
        //部署ERC20合约
        betteToken = new GamblingERC20("Betting Token", "BETTE", 100000000 * 1e18);
        //部署空合约
        emptyContract = new EmptyContract();

        //部署透明代理合约 先指向空合约
        TransparentUpgradeableProxy proxyEmpty =
            new TransparentUpgradeableProxy(address(emptyContract), deployerAddr, "");

        // 直接部署真正的实现合约
        gamblingGameManagerImplementation = new GamblingGameManager();

        //获取代理的管理员合约地址
        address proxyAdminAddr = getProxyAdminAddress(address(proxyEmpty));
        proxyAdmin = ProxyAdmin(proxyAdminAddr);

        // 准备初始化数据
        bytes memory initData = abi.encodeWithSelector(
            GamblingGameManager.initialize.selector, deployerAddr, address(betteToken), deployerAddr
        );

        //将代理合约转换为GamblingGameManager类型，方便后续操作
        gamblingGameManagerProxy = GamblingGameManager(payable(address(proxyEmpty)));
        //升级代理并初始化
        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(gamblingGameManagerProxy)),
            address(gamblingGameManagerImplementation),
            initData
        );

        console.log("Bette Token deployed at:", address(betteToken));
        console.log("GamblingGameManager Proxy deployed at:", address(gamblingGameManagerProxy));
        console.log("GamblingGameManager Implementation deployed at:", address(gamblingGameManagerImplementation));
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));
        vm.stopBroadcast();
    }

    /**
     * @notice 获取代理合约的 ProxyAdmin 地址
     * @dev ProxyAdmin 地址存储在 ERC1967 标准的 admin slot 中
     * @param proxy 代理合约地址
     * @return ProxyAdmin 合约地址
     */
    function getProxyAdminAddress(address proxy) internal view returns (address) {
        // Foundry 的作弊码地址
        address CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
        Vm vm = Vm(CHEATCODE_ADDRESS);

        // 从代理合约的 admin slot 读取 ProxyAdmin 地址
        // ERC1967Utils.ADMIN_SLOT 是存储管理员地址的标准槽位
        bytes32 adminSlot = vm.load(proxy, ERC1967Utils.ADMIN_SLOT);
        return address(uint160(uint256(adminSlot)));
    }
}
