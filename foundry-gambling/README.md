## 游戏

### 1. 每 32 块一次游戏，游戏结束后，获取随机数生成器产三个随机数字的和

#### 1.1 玩法如下：

- 单： 三个数相加为单数，则视为中奖, 赔率 1：1.95 含本金
- 双： 三个数相加为双数，则视为中奖, 赔率 1：1.95 含本金
- 大：三个数相加 14≤ sum ≤ 27，则视为中奖。赔率 1：1.95 含本金
- 小：三个数相加 0 ≤ sum ≤13，则视为中奖。赔率 1：1.95 含本金

### 2.如果用户赢，游戏结束之后直接把钱划转到玩家手中。

### 3.关于用户记录问题。

- 每个用户玩了哪几种
- 每个游戏有多少用户在玩，玩了多少（多少指的是流水和盈亏）
- 产生的流水总的和各个游戏的。
- 盈亏和流水要分开统计

### 5. Oz 库安装

```
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
```

### 6. git 安装项目依赖

```
git submodule update --init --recursive --remote
```

### 7. 生成映射文件

```
forge remappings > remappings.txt
```

### 8.合约编译

```
forge compile
```

### 9.合约构建

```
forge build
```

### 10.合约测试

```
forge test
```

### 11.合约部署

````
forge script ./script/GamblingGameDepolyer.s.sol:GamblingGameDepolyer --rpc-url  https://eth-holesky.g.alchemy.com/v2/xis9zzUnd3ts5uZmF9BipBpeWfcYBNzb --private-key $PRIVATEKEY```
````

### 12.合约验证

```
export ETHERSCAN_API_KEY=HZEZGEPJJDA633N421AYW9NE8JFNZZC7JT
forge verify-contract 0x516c3076Fb43eB158F97A66aad52a96Da8343A5E GamblingGame --compiler-version 0.8.0
```

### 13. Cast 命令使用

#### call 方法

```
cast call --rpc-url https://eth-holesky.g.alchemy.com/v2/3ewO7IUWDTEW5xiFDtUCZoayQCSSFZAH 0xD0bbDDDf88b350b1220b192A42Cddd82251828C0 "gameBlock()(uint256)"
```

```
 cast call --rpc-url https://eth-holesky.g.alchemy.com/v2/3ewO7IUWDTEW5xiFDtUCZoayQCSSFZAH 0xD0bbDDDf88b350b1220b192A42Cddd82251828C0 "betteToken()(address)"
```

#### 写

```
cast send --rpc-url https://eth-holesky.g.alchemy.com/v2/xis9zzUnd3ts5uZmF9BipBpeWfcYBNzb  --private-key $PRIVATEKEY --from 0xe3b4ECd2EC88026F84cF17fef8bABfD9184C94F0  0xD0bbDDDf88b350b1220b192A42Cddd82251828C0 "setBetteToken(address,uint256)" 0x7F82C801D1778fC42Df04c22f532C5B18bB3ba0F 18
```

### 14. 启动本地 anvil 节点

```
anvil
```

- 把投注合约自己写一遍，部署 RootHash Chain, 模拟 Oralce 抽奖过程，输出代码，oralce 的模拟代码和 Cast 命令
  Bette Token deployed at: 0x3A53322F9Fa7080Dbdf42cc7b0e1ac621cD768c2
  GamblingGameManager Proxy deployed at: 0x32aFe2A0ac95eaDddf3a9A4AcFCb71C2CB26987B
  GamblingGameManager Implementation deployed at: 0xCa1279C9c971870E743e7414d4730c77e8dcD579
  ProxyAdmin deployed at: 0xDB792656F27441B97836B18C3075743d6b9def82
  OracleMock deployed at: 0xfa4aF9Eccc9eC013A2E4Ee2F2b940e12A3f6CdF6
  LuckDrawManager implementation deployed at: 0xc4964c3d6372F1f7942cC61EE69c0eCCB7c56248
  / Layout of Contract:
  // license
  // version
  // imports
  // errors
  // interfaces, libraries, contracts
  // Type declarations
  // State variables
  // Events
  // Modifiers
  // Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external // public // internal // private
// internal & private view & pure functions
// external & public view & pure functions
