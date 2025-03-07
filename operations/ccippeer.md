## CCIPPeer Configuration Guide  

This guide outlines the essential steps for configuring `CCIPPeer` contracts across two chains. The example demonstrates configuration from **Chain A to Chain B**, and the same steps should be followed in reverse for **Chain B to Chain A** configuration.  

---  

## Prerequisites  
- **CCIPPeer contracts** deployed on both chains  
- **Admin access** to both contracts  
- **uniBTC contracts** deployed on both chains  
- **CCIP Router addresses** for both chains  

---  

## Step 1: Configure Source Chain Settings  

On **Chain A**, configure the source chain settings to allow messages from **Chain B**:  

```solidity
function allowlistSourceChain(uint64 _sourceChainSelector, address _sender) external
```

**Parameters:**  
- `_sourceChainSelector` : **Chain B's selector** from CCIP documentation  
  *(e.g., for BitLayer: `7937294810946806131`, [CCIP Directory](https://docs.chain.link/ccip/directory/mainnet/chain/bitcoin-mainnet-bitlayer-1))*  
- `_sender` : **CCIPPeer contract address** on **Chain B**  

---  

## Step 2: Configure Destination Chain Settings  

On **Chain A**, set up the destination chain configuration:  

```solidity
function allowlistDestinationChain(uint64 _destinationChainSelector, address _receiver) external
```

**Parameters:**  
- `_destinationChainSelector` : **Chain B's selector** from CCIP documentation  
  *(e.g., for BitLayer: `7937294810946806131`, [CCIP Directory](https://docs.chain.link/ccip/directory/mainnet/chain/bitcoin-mainnet-bitlayer-1))*  
- `_receiver` : **CCIPPeer contract address** on **Chain B**  

---  

## Step 3: Configure Target Tokens  

On **Chain A**, configure the target token mapping:  

```solidity
function allowlistTargetTokens(uint64 _destinationChainSelector, address _token) external
```

**Parameters:**  
- `_destinationChainSelector` : **Chain B's selector** from CCIP documentation  
  *(e.g., for BitLayer: `7937294810946806131`, [CCIP Directory](https://docs.chain.link/ccip/directory/mainnet/chain/bitcoin-mainnet-bitlayer-1))*  
- `_token` : **uniBTC contract address** on **Chain B**  

---  

## Step 4: Grant Minting Permissions  

Configure minting permissions for **CCIPPeer contracts**:  

```solidity
function grantRole(bytes32 role, address account) external
```

### **On Chain A:**  
- Call `uniBTC.grantRole(MINTER_ROLE, CCIPPeer_A_Address)`  
- Only **DEFAULT_ADMIN_ROLE** can perform this action  

### **On Chain B:**  
- Call `uniBTC.grantRole(MINTER_ROLE, CCIPPeer_B_Address)`  
- Only **DEFAULT_ADMIN_ROLE** can perform this action  

---  

## Mirror Configuration  

Repeat **all steps** on **Chain B**, using **Chain A's** parameters:  

- Use **Chain A's selector** for source/destination chain configuration  
- Use **Chain A's CCIPPeer address** for sender/receiver  
- Use **Chain A's uniBTC address** for token configuration  
