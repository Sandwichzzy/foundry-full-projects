// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IGamblingGameManager.sol";
import "../interfaces/ILuckDrawManager.sol";
import "../../test/mocks/mockOracle.sol";

contract LuckDrawManager is ILuckDrawManager, Initializable, OwnableUpgradeable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public luckyDrawer;
    address public gamblingGameManager;
    OracleMock public oracle;

    modifier onlyLuckyDrawer() {
        require(msg.sender == luckyDrawer, "LuckDrawManager: caller is not the lucky drawer");
        _;
    }

    function initialize(address initialOwner, address _luckyDrawer, address _gamblingGameManager, address _oracle)
        public
        initializer
    {
        __Ownable_init(initialOwner);
        luckyDrawer = _luckyDrawer;
        gamblingGameManager = _gamblingGameManager;
        oracle = OracleMock(_oracle);
    }

    function requestRandomNumbers() external onlyLuckyDrawer {
        uint256 requestId = oracle.requestRandomNumbers();
        emit RandomNumbersRequested(requestId);
    }

    function receiveCallback(bytes memory response) external {
        require(msg.sender == address(oracle), "LuckDrawManager: caller is not the oracle");

        // 解码随机数字
        uint256[3] memory randomNumbers = abi.decode(response, (uint256[3]));

        emit RandomNumbersReceived(randomNumbers);

        // 调用GamblingGameManager的luckyDraw函数
        IGamblingGameManager(gamblingGameManager).luckyDraw(randomNumbers);

        emit LuckyDrawExecuted(randomNumbers);
    }

    function setLuckyDrawer(address _luckyDrawer) external onlyOwner {
        luckyDrawer = _luckyDrawer;
    }

    function setGamblingGameManager(address _gamblingGameManager) external onlyOwner {
        gamblingGameManager = _gamblingGameManager;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = OracleMock(_oracle);
    }
}
