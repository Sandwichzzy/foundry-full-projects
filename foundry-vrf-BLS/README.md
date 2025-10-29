## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

### 1. Oz 库安装

```
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
```

```
=== Deployment Summary ===
UUPS Proxy Address (EmptyContract -> BLSApkRegistry): 0xd9c7A845fb93Fc1F3ECad04658a27fDcdA502B6a
TheWeb3VRFManager: 0x6235A2540D7833D48796F12C1AB25F1b8DB5E4Eb
VrfMinProxyFactory: 0x7165aaa879742299F04aC919EF3C8D0A969f778B
TheWeb3Pod proxy: 0x588679e21Fb3f984D0Db1Bc0f0b17363049BB585

=== Verification ===
Proxy owner: 0x6002BaD747AfD5690f543a670f3e3bD30E033084
WhitelistManager: 0x6002BaD747AfD5690f543a670f3e3bD30E033084
VrfManagerAddress: 0x6002BaD747AfD5690f543a670f3e3bD30E033084
```
