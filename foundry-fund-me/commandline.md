- 对比维度  
  forge test --rpc-url $SEPOLIA_RPC_URL vs forge test --fork-url $SEPOLIA_RPC_URL
- 核心功能  
  --rpc-url: 使用 RPC 节点与真实的 Sepolia 测试网交互。
  --fork-url: 将 Sepolia 测试网的状态分叉到本地，创建一个本地的模拟环境。
- 网络环境
  实时测试网 vs 本地分叉网络。
- Gas 消耗来源
  你钱包里的 真实 Sepolia 测试网 ETH。需要从水龙头获取。 vs
  本地模拟的 ETH，可以无限获取，不消耗真实测试网代币。
- 测试速度与成本
  较慢（受网络状况影响），有实际成本（消耗测试币）。vs
  极快（在本地运行），零成本。
- 主要应用场景
  需要与链上实时状态交互的最终集成测试。vs
  开发调试过程中的主力和推荐方式，用于模拟主网或测试网环境的复杂测试。
