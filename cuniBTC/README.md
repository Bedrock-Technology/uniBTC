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

git submodule add https://github.com/foundry-rs/forge-std cuniBTC/lib/forge-std
git submodule add https://github.com/OpenZeppelin/openzeppelin-contracts.git cuniBTC/lib/OpenZeppelin/openzeppelin-contracts@4.8.3
git submodule add https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable.git cuniBTC/lib/OpenZeppelin/openzeppelin-contracts-upgradeable@4.8.3

# Hoodi
## ProxyAdmin
0xB36F69446C756831cCE73bb35bb2D6f75007212c
## uniBTC
0x611160Ae2DA00A2735e3400AC4f401918A61800a

## Factory
0x677F4D7Fe9d78223041E2B0f78F5Ac7ae212b3D5
### defaultImpl
```bash
  deploy cuniBTC implementation at 0x7DbF877B6550D01155A29084Ba923bF4672f862b
  deploy vault implementation at 0xa29e2193EC161756f9fa6c0B6b9377312A53E104
  deploy airdrop implementation at 0x919B67b5949CF892Cbff9B3708f3c150C6a4aD55
  deploy delayredeemrouter implementation at 0xE17A430d8f9f1BCB5C8e3842EC5BC7362Ed676D7
```
