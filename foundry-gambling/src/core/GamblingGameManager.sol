// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IGamblingGameManager.sol";

contract GamblingGameManager is IGamblingGameManager, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    error GamblingGameManager__GameIsNotOver();

    using SafeERC20 for IERC20;

    enum BettorType {
        Big,
        Small,
        Single,
        Double
    }

    struct RoundGame {
        uint256 startBlock; // 起始区块
        uint256 endBlock; // 结束区块
        uint256[3] threeNumbers; // 三个数字
    }

    struct GuessBettor {
        address account;
        uint256 value; // 投注金额 >= 10U
        uint256 hgmId; // 游戏期数
        uint8 betType; // 投注情况
        bool hasReward; // 是否结算
        bool isReward; // 是否中奖
        uint256 rewardAmount; // 奖励金额，投注失败为 0
    }

    IERC20 public betteToken; // 博彩 Token(USDT)
    uint256 public betteTokenDecimal; // 10**6

    uint256 public gameBlock; // 游戏的每期块的数量，默认 30，可以设置
    uint256 public hgmGlobalId; // 游戏期数自增 ID,从 1 开始递增, 查看开始游戏函数
    address public luckyDrawer; // 开奖人
    address public luckDrawManager; // LuckDrawManager合约地址

    GuessBettor[] public guessBettorList; // 博彩人数

    mapping(uint256 => RoundGame) public roundGameInfo; // 每期的结果
    mapping(uint256 => mapping(address => GuessBettor)) public GuessBettorMap; // 玩家的历史记录

    modifier onlyLuckyDrawer() {
        require(luckyDrawer == msg.sender, "GamblingGameManager:onlyLuckyDrawer: caller must be lucky drawer");
        _;
    }

    modifier onlyLuckyDrawerOrManager() {
        require(
            luckyDrawer == msg.sender || luckDrawManager == msg.sender,
            "GamblingGameManager:onlyLuckyDrawerOrManager: caller must be lucky drawer or luck draw manager"
        );
        _;
    }

    function initialize(address initialOwner, address _betteToken, address _luckyDrawer) public initializer {
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();
        gameBlock = 30;
        hgmGlobalId = 1;
        betteTokenDecimal = 6;
        luckyDrawer = _luckyDrawer;
        betteToken = IERC20(_betteToken);
        uint256[3] memory fixedArray;
        roundGameInfo[hgmGlobalId] =
            RoundGame({startBlock: block.number, endBlock: block.number + gameBlock, threeNumbers: fixedArray});
    }

    //CEI
    function createBettor(uint256 _amount, uint8 _betType) external returns (bool) {
        require(
            _betType >= uint8(BettorType.Big) && _betType <= uint8(BettorType.Double),
            "GamblingGameManager:createBettor: invalid bet type"
        );
        require(_amount >= 10 ** betteTokenDecimal, "GamblingGameManager:createBettor: amount less than min bet amount");

        require(
            IERC20(betteToken).balanceOf(msg.sender) >= _amount,
            "GamblingGameManager:createBettor: insufficient balance"
        );

        require(
            roundGameInfo[hgmGlobalId].endBlock > block.number,
            "GamblingGameManager:createBettor: current round game is over, wait for next round game"
        );
        IERC20(betteToken).safeTransferFrom(msg.sender, address(this), _amount);
        GuessBettor memory gb = GuessBettor({
            account: msg.sender,
            value: _amount,
            hgmId: hgmGlobalId,
            betType: _betType,
            hasReward: false,
            isReward: false,
            rewardAmount: 0
        });
        guessBettorList.push(gb);
        emit GuessBettorCreate(msg.sender, _amount, _betType);
        return true;
    }

    function luckyDraw(uint256[3] memory _threeNumbers) external onlyLuckyDrawerOrManager {
        if (block.number < roundGameInfo[hgmGlobalId].endBlock) {
            revert GamblingGameManager__GameIsNotOver();
        }
        uint256 threeNumberResult = 0;
        for (uint8 i = 0; i < _threeNumbers.length; i++) {
            threeNumberResult += _threeNumbers[i];
        }
        for (uint256 i = 0; i < guessBettorList.length; i++) {
            uint256 reWardVale = guessBettorList[i].value * 195 / 100;
            if (
                (threeNumberResult >= 14 && threeNumberResult <= 27)
                    && (guessBettorList[i].betType == uint8(BettorType.Big))
            ) {
                // 大
                allocateReward(guessBettorList[i], reWardVale);
            }
            if (
                (threeNumberResult >= 6 && threeNumberResult <= 13)
                    && (guessBettorList[i].betType == uint8(BettorType.Small))
            ) {
                // 小
                allocateReward(guessBettorList[i], reWardVale);
            }
            if ((threeNumberResult % 2 == 1) && (guessBettorList[i].betType == uint8(BettorType.Single))) {
                // 单
                allocateReward(guessBettorList[i], reWardVale);
            }
            if ((threeNumberResult % 2 == 0) && (guessBettorList[i].betType == uint8(BettorType.Double))) {
                // 双
                allocateReward(guessBettorList[i], reWardVale);
            }
        }
        roundGameInfo[hgmGlobalId].threeNumbers = _threeNumbers;
        delete guessBettorList;
        hgmGlobalId += 1;
        uint256[3] memory fixedArray;
        roundGameInfo[hgmGlobalId] =
            RoundGame({startBlock: block.number, endBlock: block.number + gameBlock, threeNumbers: fixedArray});
    }

    function setGameBlock(uint256 _block) external onlyOwner {
        gameBlock = _block;
    }

    function setBetteToken(address _betteToken, uint256 _betteTokenDecimal) external onlyOwner {
        betteToken = IERC20(_betteToken);
        betteTokenDecimal = _betteTokenDecimal;
    }

    function setLuckDrawManager(address _luckDrawManager) external onlyOwner {
        luckDrawManager = _luckDrawManager;
    }

    function getBalance() external view returns (uint256) {
        return betteToken.balanceOf(address(this));
    }

    function allocateReward(GuessBettor memory guessBettor, uint256 _rewardValue) internal {
        guessBettor.isReward = true; // 中奖
        guessBettor.rewardAmount = _rewardValue;
        IERC20(betteToken).safeTransfer(guessBettor.account, _rewardValue);

        guessBettor.hasReward = true; // 已经结算
        emit AllocateReward(guessBettor.account, hgmGlobalId, guessBettor.betType, _rewardValue, true);
    }
}
