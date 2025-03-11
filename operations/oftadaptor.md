## uniBTCOFTAdapter Configuration Guide  

This guide outlines the configuration steps for `uniBTCOFTAdapter` contracts across two chains. The example demonstrates configuration from **Chain A to Chain B (Ethereum)**, and the same steps should be followed in reverse for **Chain B to Chain A** configuration.  

---  

## Prerequisites  

- **uniBTCOFTAdapter contracts** deployed on both chains  
- **Contract deployment information** updated in:  
  - `oft-adaptor/scripts/output/`  
  - `oft-adaptor/scripts/utils/`  
- **Admin access** to both contracts  
- **LayerZero endpoints** configured  
- **Environment variables** set up:  
  - `$RPC_ETH`: Ethereum RPC URL  
  - `$OWNER`: Admin wallet private key  

---  

## Step 1: Configure Peer Relationship  

### **On Chain A**  
Set up peer relationship with **Chain B (Ethereum)**:  

```bash
cd oft-adaptor
forge script script/SetOFTAdapter.s.sol --sig 'setPeer(uint256)' 1 --rpc-url $RPC_ChainA --account $OWNER --broadcast
```

**Parameters:**  
- `setPeer(uint256)`: Function to configure peer relationship  
- `1`: Ethereum's chain ID  
- `--account $OWNER`: Admin wallet for transaction signing  

---  

## Step 2: Grant Minting Permissions  

### **On Chain A**  
Grant minting role to **uniBTCOFTAdapter**:  

```bash
cd oft-adaptor
forge script script/SetUniBTC.s.sol --sig 'setMinter()' --rpc-url $RPC_ChainA --account $OWNER --broadcast
```

---  

## Mirror Configuration on Chain B  

Repeat the **same steps** on **Chain B (Ethereum)**, using **Chain A's parameters**:  

### **1. Configure Peer:**  
```bash
cd oft-adaptor
forge script script/SetOFTAdapter.s.sol --sig 'setPeer(uint256)' CHAIN_A_ID --rpc-url $RPC_ChainB --account $OWNER --broadcast
```

### **2. Grant Minting Permissions:**  
```bash
cd oft-adaptor
forge script script/SetUniBTC.s.sol --sig 'setMinter()' --rpc-url $RPC_ChainB --account $OWNER --broadcast
```
