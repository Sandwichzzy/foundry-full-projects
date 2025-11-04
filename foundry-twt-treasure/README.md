# TreasureManager - 智能合约财库管理系统

一个基于 Foundry 框架开发的可升级智能合约财库管理系统，支持 ETH 和 ERC20 代币的存储、奖励分发和提取功能。

## 📋 项目概述

TreasureManager 是一个采用 OpenZeppelin 可升级代理模式的财库管理智能合约，提供以下核心功能：

- 🏦 **资产存储**: 支持 ETH 和 ERC20 代币的安全存储
- 🎁 **奖励系统**: 管理员可为用户分配代币奖励
- 💰 **资产提取**: 用户可提取自己的奖励，管理员可提取合约资产
- 🔐 **权限控制**: 基于角色的访问控制系统
- ⬆️ **可升级性**: 支持合约逻辑升级

## 🏗️ 架构设计

### 合约组件

- **TreasureManager.sol**: 主要的财库管理合约实现
- **ITreasureManager.sol**: 财库管理合约接口
- **TreasureManagerScript.s.sol**: 部署脚本

### 技术栈

- **Foundry**: 以太坊开发框架
- **OpenZeppelin**: 安全的智能合约库
- **Solidity ^0.8.13**: 智能合约开发语言

## 🚀 快速开始

### 环境要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### 安装依赖

```bash
# 克隆项目
git clone <repository-url>
cd foundry-twt-treasure

# 安装依赖
forge install
```

### 编译合约

```bash
forge build
```

### 运行测试

```bash
forge test
```

### 部署合约

1. 设置环境变量：

```bash
export PRIVATE_KEY=your_private_key_here
export RPC_URL=your_rpc_url_here
```

2. 部署到测试网：

```bash
forge script script/TreasureManagerScript.s.sol:TreasureManagerScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

## 📚 合约功能

### 存储功能

#### ETH 存储

```solidity
// 直接发送ETH到合约地址
// 或调用函数
function depositETH() external payable returns (bool)
```

#### ERC20 代币存储

```solidity
function depositERC20(IERC20 tokenAddress, uint256 amount) external returns (bool)
```

### 奖励管理

#### 分配奖励（仅财库管理员）

```solidity
function grantRewards(address tokenAddress, address granter, uint256 amount) external
```

#### 查询奖励

```solidity
function queryRewards(address tokenAddress) external view returns (uint256)
```

#### 提取奖励

```solidity
// 提取单个代币奖励
function claimToken(address tokenAddress) external

// 提取所有代币奖励
function claimAllTokens() external
```

### 资产提取（仅提取管理员）

#### 提取 ETH

```solidity
function withdrawETH(address payable withdrawAddress, uint256 amount) external payable returns (bool)
```

#### 提取 ERC20 代币

```solidity
function withdrawERC20(IERC20 tokenAddress, address withdrawAddress, uint256 amount) external returns (bool)
```

### 管理功能

#### 设置代币白名单（仅财库管理员）

```solidity
function setTokenWhiteList(address tokenAddress) external
```

#### 更新提取管理员（仅合约所有者）

```solidity
function setWithdrawManager(address _withdrawManager) external
```

## 🔑 权限角色

- **Owner**: 合约所有者，可以更新提取管理员
- **TreasureManager**: 财库管理员，可以分配奖励和管理代币白名单
- **WithdrawManager**: 提取管理员，可以从合约中提取资产

## 📊 已部署合约地址

根据部署日志：

- **Implementation**: `0x09bc3071DD385DFe5A10c09F747Ac9037D66499f`
- **Proxy**: `0x388fF618Ca5c1b8F28D4E845B431Ca3D4200140e`
- **ProxyAdmin**: `0x7bC3b56AE67698632Bb25DbedDB86D00f81AF0F7`

## 🧪 测试

运行完整测试套件：

```bash
# 运行所有测试
forge test

# 运行详细测试
forge test -vvv

# 运行特定测试
forge test --match-test testDepositETH

# 生成Gas快照
forge snapshot
```

## 🔧 开发工具

### 格式化代码

```bash
forge fmt
```

### 本地节点

```bash
anvil
```

### 合约交互

```bash
# 示例：查询合约余额
cast call <contract_address> "tokenBalances(address)" <token_address> --rpc-url $RPC_URL
```

## 📈 Gas 优化

合约采用了多种 Gas 优化策略：

- 使用`SafeERC20`库避免不必要的检查
- 批量操作减少交易次数
- 重入保护确保安全性

## 🛡️ 安全特性

- **重入保护**: 使用 OpenZeppelin 的 ReentrancyGuard
- **访问控制**: 基于角色的权限管理
- **安全传输**: 使用 SafeERC20 进行代币操作
- **可升级性**: 透明代理模式支持合约升级

## 📝 许可证

UNLICENSED

**注意**: 这是一个学习项目，请在生产环境使用前进行充分的安全审计。
