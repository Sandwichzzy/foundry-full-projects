# SWToken - ERC20 Token Project

A complete ERC20 token implementation built with Foundry framework, featuring comprehensive testing and deployment scripts.

## 📋 Project Overview

SWToken is a standard ERC20 token smart contract that provides:

- Standard ERC20 functionality (transfer, approve, allowance)
- Secure implementation using OpenZeppelin contracts
- Comprehensive test coverage
- Automated deployment scripts
- Multi-network deployment support

## 🚀 Deployed Contracts

- **RootHash Network**: `0x26fc1d2B482EbA8e88535FCbA2c6dCe902B2752f`
- **Sepolia Testnet**: `0xf43C3CFF8c11F2d3ebf8C6d796Ed60020Fc66286`

## 📁 Project Structure

```
├── src/
│   ├── SWToken.sol           # Main ERC20 token contract
│   └── Manualerc20Token.sol  # Manual ERC20 implementation
├── script/
│   └── DeploySWToken.s.sol   # Deployment script
├── test/
│   └── SWTokenTest.t.sol     # Comprehensive test suite
├── lib/                      # Dependencies (OpenZeppelin, Forge-std)
└── broadcast/                # Deployment artifacts
```

## 🛠️ Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Git installed
- An Ethereum wallet with testnet ETH

## ⚡ Quick Start

### 1. Clone and Setup

```shell
git clone <your-repo-url>
cd foundry-erc20
forge install
```

### 2. Build the Project

```shell
forge build
```

### 3. Run Tests

```shell
forge test
```

### 4. Run Tests with Verbosity

```shell
forge test -vvv
```

## 📝 Available Commands

### Development

```shell
# Build contracts
forge build

# Run all tests
forge test

# Run specific test
forge test --match-test testTransfer

# Format code
forge fmt

# Generate gas snapshots
forge snapshot
```

### Deployment

```shell
# Deploy to local network (Anvil)
anvil
forge script script/DeploySWToken.s.sol --rpc-url http://localhost:8545 --private-key <your-private-key> --broadcast

# Deploy to Sepolia testnet
forge script script/DeploySWToken.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# Deploy to RootHash network
forge script script/DeploySWToken.s.sol --rpc-url $ROOTHASH_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Interaction with Cast

```shell
# Check balance
cast call <contract-address> "balanceOf(address)" <wallet-address> --rpc-url <rpc-url>

# Get token symbol
cast call <contract-address> "symbol()" --rpc-url <rpc-url>

# Get token name
cast call <contract-address> "name()" --rpc-url <rpc-url>

# Get total supply
cast call <contract-address> "totalSupply()" --rpc-url <rpc-url>
```

## 🧪 Testing

The project includes comprehensive tests covering:

- Token deployment and initialization
- Transfer functionality
- Approval and allowance mechanisms
- Edge cases and error conditions

Run tests with different verbosity levels:

```shell
forge test                # Basic output
forge test -v            # Show test results
forge test -vv           # Show test results + logs
forge test -vvv          # Show test results + logs + stack traces
```

## 🌐 Network Configuration

### Supported Networks:

- **Local (Anvil)**: `http://localhost:8545`
- **Sepolia Testnet**: Use your preferred RPC provider
- **RootHash Network**: Use RootHash RPC endpoint

### Environment Variables

Create a `.env` file in the project root:

```env
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=your_sepolia_rpc_url
ROOTHASH_RPC_URL=your_roothash_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## 📚 Documentation

- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [ERC20 Standard](https://eips.ethereum.org/EIPS/eip-20)
