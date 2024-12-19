# DEPLOY GUIDE

## Mainnet

### Deploy OFTAdapter on ETH Mainnet

```bash
forge script script/DeployOFTAdapter.s.sol --rpc-url $RPC_ETH --account $DEPLOYER --broadcast --verify --verifier-url $RPC_ETH_SCAN --etherscan-api-key $KEY_ETH_SCAN --delay 30
```

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

### Set OFTAdapter Send and RECEIVE Config on ETH SEPOLIA(OPTION)

> [!CAUTION] > \_idr 0 for SEND, 1 for RECEIVE
> empty \_requiredDVNs will use the default

setConfig(uint256 \_chainid, uint64 \_confirmations, address[] memory \_requiredDVNs, address[] memory \_optionalDVNs, uint8 \_optionalThreshold)

```bash
forge script script/SetOFTAdapter.s.sol --sig 'setConfig(uint256,uint64,address[],address[],uint8)' 17000 4 "[0x8eebf8b423B73bFCa51a1Db4B7354AA0bFCA9193,0x530fbe405189204ef459fa4b767167e4d41e3a37,0x15f5a70fc078279d7d4a7dd94811189364810111]" "[0x25f492a35ec1e60ebcf8a3dd52a815c2d167f4c3,0x4f675c48fad936cb4c3ca07d7cbf421ceeae0c75]" 1 --rpc-url $RPC_ETH_SEPOLIA --account $OWNER --broadcast
forge script script/SetOFTAdapter.s.sol --sig 'setConfig(uint256,uint64,address[],address[],uint8)' 17000 4 "[]" "[]" 0 --rpc-url $RPC_ETH_SEPOLIA --account $OWNER --broadcast
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

### Mint uniBTC on ETH SEPOLIA

mint()

```bash
forge script script/SetUniBTC.s.sol --sig 'mint()' --rpc-url $RPC_ETH_SEPOLIA --account $OWNER --broadcast
```

### SendToken on ETH SEPOLIA

sendToken(address \_recipient, uint256 \_amount, uint256 \_chainid)

```bash
forge script script/SendToken.s.sol --sig 'sendToken(address,uint256,uint256)' $OWNER_ADDRESS 100000000 17000 --rpc-url $RPC_ETH_SEPOLIA --account $OWNER --broadcast
```

### Add account to whitelist on ETH HOLESKY

addWhitelist(address[] memory \_accounts)

```bash
forge script script/SetOFTAdapter.s.sol --sig 'addWhitelist(address[])' "[$OWNER_ADDRESS]" --rpc-url $RPC_ETH_HOLESKY --account $OWNER --broadcast
```

### Get whitelist on ETH HOLESKY

getWhitelist(address[] memory \_addresses)

```bash
forge script script/GetOFTAdapterConfig.s.sol --sig 'getWhitelist(address[])' "[$OWNER_ADDRESS]" --rpc-url $RPC_ETH_HOLESKY
```
