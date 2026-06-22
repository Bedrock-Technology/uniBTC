# Mainnet
## Factory
0x6F10dC7dc5ff3Cbb7C18B324AbDC05fADe601370
## suniBTC
```bash
{
  name (string) : suniBTC
  symbol (string) : suniBTC
  vault (address) : 0xB8b0aEd0a1Ce913183665B71bD9653fe378f2230
  suniBTC (address) : 0x8731E4a2B68E72bB22CEbF6fb45A8902Cb57129d
  delayRedeemRouter (address) : 0x641dc9E75A1b0a4c011926C4Aa1BB4721778EC2a
  airdrop (address) : 0x9eB0ba9722f2F60ef87E569628eC99f952974307
}

SymbioticProxy: 0x581d1860AeC248BB59E8f8345C70dA71dFDeA31D
```

# deploy
## deploy implemention
```bash
forge script script/defaultImpl.s.sol --sig 'deploy()' \
--rpc-url $RPC_ETH --account $DEPLOYER --broadcast \
--verify --verifier-url $RPC_ETH_SCAN --etherscan-api-key $KEY_ETH_SCAN --delay 30
== Logs ==
  deploy cuniBTC implementation at 0x2479185e254d5efeA735fC6FF7fd921fF0af43F3
  deploy vault implementation at 0x285AFd3688a20aa854b9AED89e538CF85177b458
  deploy airdrop implementation at 0x109228348113fe837207E033fdBcE3bb5f19BdA9
  deploy delayredeemrouter implementation at 0x3C4C2f4d6e45C23DF2B02b94168A5f0d378faeAe
```
## deploy factory
```bash
forge script script/factory.sol --sig 'deploy(address,address,address,address,address)' \
0x029E4FbDAa31DE075dD74B2238222A08233978f6 0x2479185e254d5efeA735fC6FF7fd921fF0af43F3 0x285AFd3688a20aa854b9AED89e538CF85177b458 0x109228348113fe837207E033fdBcE3bb5f19BdA9 0x3C4C2f4d6e45C23DF2B02b94168A5f0d378faeAe \
--rpc-url $RPC_ETH --account $DEPLOYER --broadcast \
--verify --verifier-url $RPC_ETH_SCAN --etherscan-api-key $KEY_ETH_SCAN --delay 30
== Logs ==
  deploy factory proxy at 0x6F10dC7dc5ff3Cbb7C18B324AbDC05fADe601370
  proxyAdmin 0x029E4FbDAa31DE075dD74B2238222A08233978f6
```
## create suniBTC Strategy
```bash
forge script script/factory.sol --sig 'createStrategy(address,string,string,address,address,uint256)' \
0x6F10dC7dc5ff3Cbb7C18B324AbDC05fADe601370 "suniBTC" "suniBTC" $OWNER_ADDRESS 0x004e9c3ef86bc1ca1f0bb5c7662861ee93350568 40e8 \
--rpc-url $RPC_ETH --account $DEPLOYER --broadcast
```
## e2e test
```bash
TOKEN_SYMBOL="suniBTC" forge test test/Factoryfork.t.sol --match-test 'testE2E' --rpc-url $RPC_ETH
```
## deploy SymbioticProxy 
```bash
forge script script/SymbioticProxy.s.sol --sig 'deploy(address,address,address,address,address)' \
0x9ee1881cc42478f3d0cf9b76a0135ece398af1f7 0x51329193eB24924CE48E8c5d7588Dd6187392A83 0xB8b0aEd0a1Ce913183665B71bD9653fe378f2230 0x004e9c3ef86bc1ca1f0bb5c7662861ee93350568 $OWNER_ADDRESS \
--rpc-url $RPC_ETH --account $DEPLOYER --broadcast \
--verify --verifier-url $RPC_ETH_SCAN --etherscan-api-key $KEY_ETH_SCAN --delay 30
== Logs ==
  SymbioticProxy deployed at: 0x581d1860AeC248BB59E8f8345C70dA71dFDeA31D
  owner: 0xac07f2721EcD955c4370e7388922fA547E922A4f
  symbioticVault: 0x9ee1881Cc42478F3d0Cf9b76A0135ece398AF1F7
  defaultStakerRewards: 0x51329193eB24924CE48E8c5d7588Dd6187392A83
  vault: 0xB8b0aEd0a1Ce913183665B71bD9653fe378f2230
  uniBTC: 0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568
  admin: 0xac07f2721EcD955c4370e7388922fA547E922A4f
```
## set suniBTC params
1. DelayRedeemRouter. setMaxQuotaForTokens and setQuotaRates to enable withdrawal
2. Vault. grant SymbioticProxy OPERATE_ROLE and add target for symbioticVault, defaultStakerRewards



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

