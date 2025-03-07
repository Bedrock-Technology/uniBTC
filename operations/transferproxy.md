## TransferProxy Operation Guide  

The `TransferProxy` contract is designed to facilitate the transfer of native tokens and ERC20 tokens from a vault to a specified contract address. Below are the steps and details for operating the `TransferProxy` contract.  

---  

## Contract Initialization  

The `TransferProxy` contract is initialized with two immutable addresses:  
- **vault**: The address of the vault from which tokens will be transferred.  
- **to**: The address of the contract to which tokens will be sent. This must be a contract address.  

### Constructor  
```solidity
constructor(address _vault, address _to) Ownable()
```
**Parameters:**  
- `_vault` : Address of the vault.  
- `_to` : Address of the recipient contract. Must be a valid contract address.  

---  

## Functions  

### Transfer Native Tokens  
Transfers a specified amount of native tokens from the vault to the recipient contract.  

```solidity
function transfer(uint256 _amount) external onlyOwner
```

**Parameters:**  
- `_amount` : The amount of native tokens to transfer. Must be greater than zero.  

---  

### Transfer ERC20 Tokens  
Transfers a specified amount of ERC20 tokens from the vault to the recipient contract.  

```solidity
function transfer(address _token, uint256 _amount) external onlyOwner
```

**Parameters:**  
- `_token` : The address of the ERC20 token contract.  
- `_amount` : The amount of tokens to transfer. Must be greater than zero.  

---  

## Access Control  

- The `TransferProxy` contract uses the `Ownable` pattern from OpenZeppelin, meaning **only the owner** of the contract can execute transfer functions.  
- Ensure the owner account is **securely managed** to prevent unauthorized transfers.  

---  

## Usage Example  

1. **Deploy the Contract**: Deploy the `TransferProxy` contract with the vault and recipient contract addresses.  
2. **Transfer Native Tokens**: Call the `transfer(uint256 _amount)` function to transfer native tokens.  
3. **Transfer ERC20 Tokens**: Call the `transfer(address _token, uint256 _amount)` function to transfer ERC20 tokens.  
