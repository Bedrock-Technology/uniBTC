# Depoly

## BurnMintTokenPool

- ETH

```bash
forge script script/DeployBurnMintTokenPool.s.sol --rpc-url $RPC_ETH --account $DEPLOYER --broadcast --verify --verifier-url $RPC_ETH_SCAN --etherscan-api-key $KEY_ETH_SCAN --delay 30
```

- BSC

```bash
forge script script/DeployBurnMintTokenPool.s.sol --rpc-url $RPC_BSC --account $DEPLOYER --broadcast --verify --verifier-url $RPC_BSC_SCAN --etherscan-api-key $KEY_BSC_SCAN --delay 30
```

- ARB

```bash
forge script script/DeployBurnMintTokenPool.s.sol --rpc-url $RPC_ARB --account $DEPLOYER --broadcast --verify --verifier-url $RPC_ARB_SCAN --etherscan-api-key $KEY_ARB_SCAN --delay 30
```

- OP

```bash
forge script script/DeployBurnMintTokenPool.s.sol --rpc-url $RPC_OP --account $DEPLOYER --broadcast --verify --verifier-url $RPC_OP_SCAN --etherscan-api-key $KEY_OP_SCAN --delay 30
```

- Mode

```bash
forge script script/DeployBurnMintTokenPool.s.sol --rpc-url $RPC_MODE --account $DEPLOYER --broadcast --verify --verifier-url $RPC_MODE_SCAN --etherscan-api-key $KEY_MODE_SCAN --delay 30
```

## Claim Admin Role

ask chainlink Team for manual registration  
fork test below, tokenAdminRegistry's owner on ETH is 0x44835bBBA9D40DEDa9b64858095EcFB2693c9449

```bash
cast rpc anvil_impersonateAccount {tokenAdminRegistry owner address} --rpc-url $RPC_ETH
forge script script/ClaimAdmin.s.sol --rpc-url $RPC_ETH --broadcast --sender {tokenAdminRegistry owner address} --unlocked {tokenAdminRegistry owner address}
```

## Accept Admin Role

```bash
forge script script/AcceptAdminRole.s.sol --rpc-url $RPC_ETH --account $OWNER --broadcast
```

## Set Token Pool

Setting the pool to address(0) effectively delists the token from CCIP. Setting the pool to any other address enables the token on CCIP.

```bash
forge script script/SetPool.s.sol --rpc-url $RPC_ETH --account $OWNER --broadcast
```

## Apply Chain Updates

| Parameter       | Description                                                                                                                                       |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| \_remoteChianId | The chainId of remote chain.                                                                                                                      |
| \_allowed       | A boolean indicating whether cross-chain transfers to the remote chain are allowed.                                                               |
| \_outbound      | Configuration for outbound rate limiting (transfers from current chain to remote chain). This is a struct with fields: isEnabled, capacity, rate. |
| \_inbound       | Configuration for inbound rate limiting (transfers from remote chain to current chain). This is a struct with fields: isEnabled, capacity, rate.  |

| Sub-Parameter | Description                                                                                                        |
| ------------- | ------------------------------------------------------------------------------------------------------------------ |
| isEnabled     | A flag indicating whether rate limiting is enabled (true or false).                                                |
| capacity      | The maximum number of tokens allowed in the bucket for rate limiting. Applicable only if rate limiting is enabled. |
| rate          | The rate at which tokens are refilled into the bucket per second. Applicable only if rate limiting is enabled.     |

applyChain(uint256 \_remoteChainId, bool \_allowed, RateLimiter.Config memory \_outbound, RateLimiter.Config memory \_inbound)

```bash
forge script script/ApplyChainUpdates.s.sol --sig 'applyChain(uint256,bool,(bool,uint128,uint128),(bool,uint128,uint128))' 123 true "(true,200000000,2315)" "(true,200000000,2315)" --rpc-url $RPC_ETH --account $OWNER --broadcast
```

### for eth

- to bnbChain

```bash
forge script script/ApplyChainUpdates.s.sol --sig 'applyChain(uint256,bool,(bool,uint128,uint128),(bool,uint128,uint128))' 56 true "(true,200000000,2315)" "(true,200000000,2315)" --rpc-url $RPC_ETH --account $OWNER --broadcast
```

- to arb

```bash
forge script script/ApplyChainUpdates.s.sol --sig 'applyChain(uint256,bool,(bool,uint128,uint128),(bool,uint128,uint128))' 42161 true "(true,200000000,2315)" "(true,200000000,2315)" --rpc-url $RPC_ETH --account $OWNER --broadcast
```

### for bnbChain

- to eth

```bash
forge script script/ApplyChainUpdates.s.sol --sig 'applyChain(uint256,bool,(bool,uint128,uint128),(bool,uint128,uint128))' 1 true "(true,200000000,2315)" "(true,200000000,2315)" --rpc-url $RPC_BSC --account $OWNER --broadcast
```

- to arb

```bash
forge script script/ApplyChainUpdates.s.sol --sig 'applyChain(uint256,bool,(bool,uint128,uint128),(bool,uint128,uint128))' 42161 true "(true,200000000,2315)" "(true,200000000,2315)" --rpc-url $RPC_BSC --account $OWNER --broadcast
```

### for arb

- to eth

```bash
forge script script/ApplyChainUpdates.s.sol --sig 'applyChain(uint256,bool,(bool,uint128,uint128),(bool,uint128,uint128))' 1 true "(true,200000000,2315)" "(true,200000000,2315)" --rpc-url $RPC_ARB --account $OWNER --broadcast
```

- to bnbChain

```bash
forge script script/ApplyChainUpdates.s.sol --sig 'applyChain(uint256,bool,(bool,uint128,uint128),(bool,uint128,uint128))' 56 true "(true,200000000,2315)" "(true,200000000,2315)" --rpc-url $RPC_ARB --account $OWNER --broadcast
```

### for op

- to mode

```bash
forge script script/ApplyChainUpdates.s.sol --sig 'applyChain(uint256,bool,(bool,uint128,uint128),(bool,uint128,uint128))' 34443 true "(true,200000000,2315)" "(true,200000000,2315)" --rpc-url $RPC_OP --account $OWNER --broadcast
```

### for mode

- to op

```bash
forge script script/ApplyChainUpdates.s.sol --sig 'applyChain(uint256,bool,(bool,uint128,uint128),(bool,uint128,uint128))' 10 true "(true,200000000,2315)" "(true,200000000,2315)" --rpc-url $RPC_MODE --account $OWNER --broadcast
```

## Update RateLimit(OPTIONAL)

updateRL(uint256 \_remoteChainId, RateLimiter.Config memory \_outbound, RateLimiter.Config memory \_inbound)

```bash
forge script script/UpdateRateLimiters.s.sol --sig 'updateRL(uint256,(bool,uint128,uint128),(bool,uint128,uint128))' 123 "(true,123,123)" "(true,456,456)" --rpc-url $RPC_ETH --account $OWNER --broadcast
```

## Get Pool Config

```bash
forge script script/GetPoolConfig.s.sol --rpc-url $RPC_ETH --account $OWNER
```

## Transfer Tokens

sendToken(uint256 \_destinationChainId, uint256 \_amount)

```bash
forge script script/TransferTokens.s.sol --sig 'sendToken(uint256,uint256)' 56 1 --rpc-url $RPC_ETH --account $OWNER --broadcast
```
