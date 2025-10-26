# VRF MinProxy - 可验证随机函数最小代理系统

基于 Foundry 构建的 VRF（可验证随机函数）系统，使用最小代理模式和 ECDSA 签名验证机制，为 DeFi 应用提供安全、可验证的随机数服务。

## 🌟 项目特性

- **🔐 ECDSA 签名验证**: Oracle 使用私钥签名，链上验证确保随机数真实性
- **⚡ 最小代理模式**: 使用 EIP-1167 标准，显著降低部署成本
- **🏭 工厂模式**: 支持为多个项目创建独立的 VRF 实例
- **🛡️ 安全防护**:
  - 签名重放攻击保护
  - 时间戳过期验证
  - 授权访问控制
- **🧪 全面测试**: 包含完整的集成测试和边界条件测试

## 📋 系统架构

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Application   │◄──►│  VrfManager      │◄──►│  MockVrfOracle  │
│                 │    │     (Proxy)      │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              ▲                           ▲
                              │                           │
                       ┌──────────────────┐              │
                       │ VrfMinProxyFactory│              │
                       │    (Factory)      │              │
                       └──────────────────┘              │
                                                          │
                       ┌─────────────────────────────────┘
                       │
                ┌─────────────────┐
                │ ECDSA Signature │
                │   Verification  │
                └─────────────────┘
```

## 🚀 快速开始

### 环境要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### 安装

```bash
git clone <repository-url>
cd foundry_vrf_minProxy
forge install
```

### 编译

```bash
forge build
```

### 测试

```bash
# 运行所有测试
forge test

# 运行集成测试
forge test --match-contract VRFIntegrationTest

# 详细输出
forge test -vv

# 带Gas报告
forge test --gas-report
```

## 🛠️ 部署

### 本地部署

```bash
# 启动本地测试网络
anvil

# 部署合约（新终端）
make deploy-roothash
```

### 测试网部署

```bash
# 设置环境变量
export PRIVATE_KEY=<your-private-key>
export RPC_URL=<testnet-rpc-url>

# 部署到测试网
forge script script/DeployMinProxyVRF.s.sol:DeployMinProxyVRFScript \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast
```

## 📚 核心合约

### VrfManager

VRF 管理合约，负责：

- 随机数请求管理
- ECDSA 签名验证
- Oracle 公钥配置

```solidity
// 请求随机数
function requestRandomWords(uint256 requestId, uint256 numWords) external;

// 验证并接收签名的随机数
function fulfillRandomWordsWithSignature(
    uint256 requestId,
    uint256[] memory randomWords,
    uint256 timestamp,
    bytes memory signature
) external;
```

### VrfMinProxyFactory

工厂合约，负责：

- 创建 VrfManager 代理实例
- 管理所有代理合约
- 支持 CREATE2 确定性部署

```solidity
// 创建新的代理合约
function createProxy(bytes32 salt) external returns (address);

// 预计算代理地址
function computeProxyAddress(bytes32 salt) external view returns (address);
```

### MockVrfOracle

模拟 Oracle 合约，负责：

- 接收随机数请求
- 生成随机数
- 创建 ECDSA 签名
- 回调 VrfManager

## 🔐 签名验证流程

1. **请求阶段**: 应用调用 VrfManager 请求随机数
2. **生成阶段**: Oracle 链下生成随机数和时间戳
3. **签名阶段**: Oracle 使用私钥对数据进行 ECDSA 签名
4. **验证阶段**: VrfManager 验证签名的有效性
5. **存储阶段**: 验证通过后存储随机数结果

```solidity
// 消息哈希构造
bytes32 messageHash = keccak256(abi.encodePacked(
    address(vrfManager),
    requestId,
    randomWords,
    timestamp,
    block.chainid
));

// 签名验证
address recoveredSigner = messageHash.toEthSignedMessageHash().recover(signature);
require(recoveredSigner == oraclePublicKey, "Invalid signature");
```

## 📊 最新部署信息

**本地测试网络部署结果 RootHash:**

- 部署者地址: `0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38`
- Oracle 签名者: `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
- MockVrfOracle: `0x7ea23d96eCDF63f3225264953D1A5EccFf6b2d8E`
- VrfManager 实现: `0xfEe9A3fE26fdA1DaCC90bBEE42CaDA2e00D4327f`
- 代理工厂: `0x827CECc85B7b14E345F501bf2D307736f072487d`
- 首个代理: `0x1B437C9Fc2BF61cC3B6685fAb594c33800d71460`

## 🔧 配置说明

### Oracle 配置

```solidity
// Oracle签名者地址（拥有私钥用于签名）
address public constant ORACLE_SIGNER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

// Oracle操作员（可以触发fulfillment）
address public oracleOperator;

// 签名有效期（默认5分钟）
uint256 public signatureExpiry = 300;
```

### 安全参数

- **签名有效期**: 300 秒（可配置）
- **重放攻击保护**: 每个签名只能使用一次
- **权限控制**: 只有所有者可以请求随机数
- **Oracle 验证**: 只有授权的 Oracle 可以提供随机数

## 📖 使用示例

### 基本用法

```solidity
// 1. 获取VrfManager实例
VrfManager vrfManager = VrfManager(proxyAddress);

// 2. 请求随机数
uint256 requestId = 1;
uint256 numWords = 3;
vrfManager.requestRandomWords(requestId, numWords);

// 3. 检查结果（Oracle完成后）
(bool fulfilled, uint256[] memory randomWords) = vrfManager.getRequestDetails(requestId);
if (fulfilled) {
    // 使用随机数
    for (uint256 i = 0; i < randomWords.length; i++) {
        console.log("Random word", i, ":", randomWords[i]);
    }
}
```

### 创建新项目代理

```solidity
// 使用工厂创建新项目的代理
bytes32 salt = keccak256("my_project");
address newProxy = factory.createProxy(salt);

// 初始化代理
VrfManager(newProxy).initialize(
    projectOwner,
    oracleAddress,
    oraclePublicKey
);
```

## 🔗 相关资源

- [Foundry 文档](https://book.getfoundry.sh/)
- [OpenZeppelin 合约库](https://docs.openzeppelin.com/contracts/)
- [EIP-1167: 最小代理标准](https://eips.ethereum.org/EIPS/eip-1167)
- [ECDSA 签名标准](https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm)
