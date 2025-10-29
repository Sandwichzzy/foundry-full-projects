# TheWeb3 VRF-BLS 项目

基于 Foundry 和 OpenZeppelin 升级框架的去中心化随机数生成项目，采用 BLS 签名和 UUPS 代理升级模式。

## 🚀 项目概述

本项目实现了一个完整的 VRF（可验证随机函数）系统，具有以下特性：

- **BLS 聚合签名**：支持多签名者的高效签名聚合
- **UUPS 代理升级**：可升级的智能合约架构
- **VRF 随机数生成**：安全可验证的随机数生成
- **白名单管理**：细粒度的权限控制系统

## 📋 系统架构

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   EmptyContract │───▶│  BLSApkRegistry  │───▶│ TheWeb3VRFManager│
│   (UUPS 代理)   │    │  (升级后逻辑)    │    │  (VRF 管理器)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │TheWeb3VRFFactory │
                       │  (代理工厂)      │
                       └──────────────────┘
```

## 🛠 技术栈

- **Foundry**: 以太坊开发框架
- **OpenZeppelin**: 安全的智能合约库
- **Solidity**: ^0.8.20
- **UUPS**: 可升级代理模式
- **BLS**: 聚合签名算法

## 📦 安装和设置

### 1. 克隆仓库

```bash
git clone <repository-url>
cd foundry-vrf-BLS
```

### 2. 安装依赖

```bash
# 安装 Foundry 依赖
make install

# 或者手动安装
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
forge install OpenZeppelin/openzeppelin-foundry-upgrades --no-commit
forge install foundry-rs/forge-std@v1.11.0 --no-commit
```

### 3. 环境配置

创建 `.env` 文件并配置必要的环境变量：

```bash
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=your_sepolia_rpc_url
ROOTHASH_RPC_URL=your_roothash_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## 🔧 开发工具

### 构建项目

```bash
forge build
```

### 运行测试

```bash
forge test
```

### 代码格式化

```bash
forge fmt
```

### 生成快照

```bash
forge snapshot
```

### 启动本地节点

```bash
# 使用预设的测试助记词启动 Anvil
anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# 或使用 Makefile
make anvil
```

## 🚀 部署指南

### 本地部署

```bash
# 确保 Anvil 正在运行
make anvil

# 在新终端中执行部署
make deploy-roothash
```

### 测试网部署

#### Sepolia 网络

```bash
make deploy-sepolia
```

#### RootHash 网络

```bash
# 设置环境变量后执行
NETWORK_ROOTHASH="--rpc-url $(ROOTHASH_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv"
forge script script/TheWeb3VRFDeploy.s.sol:TheWeb3VRFDepolyScript $(NETWORK_ROOTHASH)
```

## 📊 已部署合约地址

### 最新部署 (本地测试网)

```
🔗 UUPS Proxy (EmptyContract -> BLSApkRegistry): 0xbaE0076Ef6fD16Fb87c5CB46f62dB5a3f5ebF820
🎯 TheWeb3VRFManager: 0x1F09017B86392f379307158BA5450b0306d6884d
🏭 TheWeb3VRFFactory: 0x552b1B98e9Bb55159281467341733Cb095100A22
📦 TheWeb3Pod Proxy: 0xe64068ab67AfDaa433F0d9464f0bfF96942eC4bB

👤 Proxy Owner: 0x6002BaD747AfD5690f543a670f3e3bD30E033084
🛡️ WhitelistManager: 0x6002BaD747AfD5690f543a670f3e3bD30E033084
⚡ VrfManagerAddress: 0x6002BaD747AfD5690f543a670f3e3bD30E033084
```

## 🔄 UUPS 升级机制

### 升级流程

1. **初始部署**: 部署 `EmptyContract` 作为 UUPS 代理
2. **逻辑升级**: 将代理升级到 `BLSApkRegistry`
3. **状态初始化**: 使用 `initializeV2` 函数初始化新状态

### 升级后初始化

```solidity
    ///@custom:oz-upgrades-validate-as-initializer
    function initializeV2(address _initialOwner, address _whitelistManager, address _vrfManagerAddress)
        external
        reinitializer(2)
    {
        // 重新初始化父合约（即使已经初始化过，使用 reinitializer(2) 是安全的）
        __Ownable_init(_initialOwner); // 保持原有所有者
        __UUPSUpgradeable_init();
        __EIP712_init("BLSApkRegistry", "v0.0.1");

        whitelistManager = _whitelistManager;
        vrfManagerAddress = _vrfManagerAddress;
        _initializeApk();
    }
```

### 跳过验证部署 (如需要)

```bash
forge script script/UpgradeBLSApkRegistry.s.sol:UpgradeBLSApkRegistry \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  --unsafe \
  -vvvv
```

## 🐛 故障排除

### 常见问题

#### 1. `InvalidInitialization()` 错误

**原因**: 尝试重复调用 `initializer` 函数
**解决方案**: 使用 `reinitializer(version)` 或确保只调用一次初始化

#### 2. 升级安全验证失败

**原因**: OpenZeppelin 升级工具检测到不安全的升级
**解决方案**:

- 检查存储布局兼容性
- 使用 `--unsafe` 标志跳过验证（谨慎使用）
- 确保构造函数正确使用 `_disableInitializers()`

#### 3. Node.js 版本不兼容

**原因**: 使用了不支持的 Node.js 版本
**解决方案**:

```bash
# 安装 Node.js LTS 版本
nvm install --lts
nvm use --lts
```

#### 4. RPC 连接失败

**原因**: 本地节点未启动或 RPC URL 错误
**解决方案**:

- 确保 Anvil 正在运行: `make anvil`
- 检查 `.env` 文件中的 RPC URL 配置

## 🧪 测试

### 运行所有测试

```bash
forge test
```

### 运行特定测试

```bash
forge test --match-test testFunctionName
```

### 生成覆盖率报告

```bash
forge coverage
```

## 📚 文档参考

- [Foundry 官方文档](https://book.getfoundry.sh/)
- [OpenZeppelin 升级指南](https://docs.openzeppelin.com/upgrades-plugins/1.x/)
- [UUPS 代理模式](https://eips.ethereum.org/EIPS/eip-1822)
- [BLS 签名算法](https://tools.ietf.org/html/draft-irtf-cfrg-bls-signature-04)
