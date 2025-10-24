// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/core/GamblingGameManager.sol";
import "../src/core/LuckDrawManager.sol";
import "../test/mocks/mockOracle.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDT is ERC20 {
    constructor() ERC20("Mock USDT", "USDT") {
        _mint(msg.sender, 1000000 * 10 ** 6); // 100万 USDT
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}

contract OracleLuckyDrawTest is Test {
    GamblingGameManager public gamblingGame;
    LuckDrawManager public luckDrawManager;
    OracleMock public oracle;
    MockUSDT public usdt;

    address public owner = address(0x1);
    address public luckyDrawer = address(0x2);
    address public player1 = address(0x3);
    address public player2 = address(0x4);

    function setUp() public {
        vm.startPrank(owner);

        // 部署USDT代币
        usdt = new MockUSDT();

        // 部署Oracle
        oracle = new OracleMock();

        // 部署GamblingGameManager
        gamblingGame = new GamblingGameManager();
        gamblingGame.initialize(owner, address(usdt), luckyDrawer);

        // 部署LuckDrawManager
        luckDrawManager = new LuckDrawManager();
        luckDrawManager.initialize(owner, luckyDrawer, address(gamblingGame), address(oracle));

        // 设置GamblingGameManager的LuckDrawManager地址
        gamblingGame.setLuckDrawManager(address(luckDrawManager));

        // 给玩家分配代币
        usdt.transfer(player1, 1000 * 10 ** 6); // 1000 USDT
        usdt.transfer(player2, 1000 * 10 ** 6); // 1000 USDT

        vm.stopPrank();
    }

    function testOracleLuckyDrawFlow() public {
        // 1. 玩家下注
        vm.startPrank(player1);
        usdt.approve(address(gamblingGame), 100 * 10 ** 6);
        gamblingGame.createBettor(100 * 10 ** 6, 0); // 押大
        vm.stopPrank();

        vm.startPrank(player2);
        usdt.approve(address(gamblingGame), 50 * 10 ** 6);
        gamblingGame.createBettor(50 * 10 ** 6, 1); // 押小
        vm.stopPrank();

        // 2. 跳过游戏区块数，使游戏结束
        vm.roll(block.number + 31);

        // 3. 通过LuckDrawManager请求Oracle获取随机数字
        vm.startPrank(luckyDrawer);

        // 请求随机数字，这会触发整个流程
        luckDrawManager.requestRandomNumbers();

        vm.stopPrank();

        // 4. 验证结果
        // 检查是否生成了新的游戏轮次
        assertEq(gamblingGame.hgmGlobalId(), 2, "Game should proceed to next round");

        // 检查Oracle请求记录
        OracleMock.Request memory request = oracle.getRequest(0);
        assertTrue(request.fulfilled, "Oracle request should be fulfilled");

        // 解码随机数字
        uint256[3] memory randomNumbers = abi.decode(request.response, (uint256[3]));

        // 验证随机数字在正确范围内 (1-6)
        for (uint8 i = 0; i < 3; i++) {
            assertTrue(randomNumbers[i] >= 1 && randomNumbers[i] <= 6, "Random number should be between 1 and 6");
        }

        console.log("Generated random numbers:");
        console.log("Number 1:", randomNumbers[0]);
        console.log("Number 2:", randomNumbers[1]);
        console.log("Number 3:", randomNumbers[2]);
        console.log("Sum:", randomNumbers[0] + randomNumbers[1] + randomNumbers[2]);

        console.log("Successfully completed Oracle -> LuckDraw flow!");
    }

    function testMultipleOracleRequests() public {
        // 测试多次Oracle请求
        vm.startPrank(luckyDrawer);

        for (uint256 i = 0; i < 3; i++) {
            // 玩家下注
            vm.startPrank(player1);
            usdt.approve(address(gamblingGame), 10 * 10 ** 6);
            gamblingGame.createBettor(10 * 10 ** 6, 0); // 押大
            vm.stopPrank();

            // 跳过游戏区块
            vm.roll(block.number + 31);

            // 请求随机数字
            vm.startPrank(luckyDrawer);
            luckDrawManager.requestRandomNumbers();
            vm.stopPrank();

            // 验证请求被处理
            OracleMock.Request memory request = oracle.getRequest(i);
            assertTrue(request.fulfilled, string(abi.encodePacked("Request ", vm.toString(i), " should be fulfilled")));
        }

        console.log("Successfully processed", 3, "Oracle requests");
    }

    function testUnauthorizedOracleCallback() public {
        // 测试未授权的Oracle回调应该失败
        vm.startPrank(player1);

        bytes memory fakeResponse = abi.encode([uint256(1), uint256(2), uint256(3)]);

        vm.expectRevert("LuckDrawManager: caller is not the oracle");
        luckDrawManager.receiveCallback(fakeResponse);

        vm.stopPrank();
    }
}
