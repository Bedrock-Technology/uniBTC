# DEPLOY GUIDE

## Testnet

### Deploy uniBTC on ETH SEPOLIA

```bash
forge script script/DeployUniBTC.s.sol --rpc-url $RPC_ETH_SEPOLIA --account $DEPLOYER --broadcast --verify --verifier-url $RPC_ETH_SEPOLIA_SCAN --etherscan-api-key $KEY_ETH_SEPOLIA_SCAN --delay 30
```

### Deploy uniBTC on ETH HOLESKY

```bash
forge script script/DeployUniBTC.s.sol --rpc-url $RPC_ETH_HOLESKY --account $DEPLOYER --broadcast --verify --verifier-url $RPC_ETH_HOLESKY_SCAN --etherscan-api-key $KEY_ETH_HOLESKY_SCAN --delay 30
```

### Deploy OFTAdapter on ETH SEPOLIA

```bash
forge script script/DeployOFTAdapter.s.sol --rpc-url $RPC_ETH_SEPOLIA --account $DEPLOYER --broadcast --verify --verifier-url $RPC_ETH_SEPOLIA_SCAN --etherscan-api-key $KEY_ETH_SEPOLIA_SCAN --delay 30
```

### Deploy OFTAdapter on ETH HOLESKY

```bash
forge script script/DeployOFTAdapter.s.sol --rpc-url $RPC_ETH_HOLESKY --account $DEPLOYER --broadcast --verify --verifier-url $RPC_ETH_HOLESKY_SCAN --etherscan-api-key $KEY_ETH_HOLESKY_SCAN --delay 30
```

### Set OFTAdapter Peer on ETH SEPOLIA

setPeer(uint256 \_chainid)

```bash
forge script script/SetOFTAdapter.s.sol --sig 'setPeer(uint256)' 17000 --rpc-url $RPC_ETH_SEPOLIA --account $OWNER --broadcast
```

### Set OFTAdapter Send Config on ETH SEPOLIA(OPTION)

setSendConfig(uint256 \_chainid, uint64 \_confirmations, address[] memory \_requiredDVNs)

```bash
forge script script/SetOFTAdapter.s.sol --sig 'setSendConfig(uint256, uint64,address[])' 17000 10 "[0x8eebf8b423B73bFCa51a1Db4B7354AA0bFCA9193]" --rpc-url $RPC_ETH_SEPOLIA --account $OWNER --broadcast
```

### Set OFTAdapter Peer on ETH HOLESKY

setPeer(uint256 \_chainid)

```bash
forge script script/SetOFTAdapter.s.sol --sig 'setPeer(uint256)' 11155111 --rpc-url $RPC_ETH_HOLESKY --account $OWNER --broadcast
```

### Set uniBTC minter on ETH SEPOLIA

setMinter()

```bash
forge script script/SetUniBTC.s.sol --sig 'setMinter()' --rpc-url $RPC_ETH_SEPOLIA --account $OWNER --broadcast
```

### Set uniBTC minter on ETH HOLESKY

setMinter()

```bash
forge script script/SetUniBTC.s.sol --sig 'setMinter()' --rpc-url $RPC_ETH_HOLESKY --account $OWNER --broadcast
```

### Get Config on ETH SEPOLIA

getConfig()

```bash
forge script script/GetOFTAdapterConfig.s.sol --sig 'getConfig()' --rpc-url $RPC_ETH_SEPOLIA
```

### Get Config on ETH HOLESKY

getConfig()

```bash
forge script script/GetOFTAdapterConfig.s.sol --sig 'getConfig()' --rpc-url $RPC_ETH_HOLESKY
```

### Set uniBTC mint on ETH SEPOLIA

mint()

```bash
forge script script/SetUniBTC.s.sol --sig 'mint()' --rpc-url $RPC_ETH_SEPOLIA --account $OWNER --broadcast
```

### SendToken on ETH SEPOLIA

sendToken(address \_recipient, uint256 \_amount, uint256 \_chainid)

```bash
forge script script/SendToken.s.sol --sig 'sendToken(address,uint256,uint256)' $OWNER_ADDRESS 100000000 17000 --rpc-url $RPC_ETH_SEPOLIA --account $OWNER --broadcast
```
