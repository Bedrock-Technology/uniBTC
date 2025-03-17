## DelayRedeemRouter Configuration Guide  

This guide outlines the essential steps for configuring the `DelayRedeemRouter` contract. Follow these steps in order.  

---  

## Step 1: Add BTC Tokens to Whitelist  

This function adds supported BTC tokens to the `btclist`. Only listed tokens can be used for redemption.  

- **Native BTC address**: `0xbeDFFfFfFFfFfFfFFfFfFFFFfFFfFFffffFFFFFF`  
- Each token must be a valid BTC token contract address  
- **Only the admin** can call this function  
- Multiple tokens can be added in a single transaction  

### Function:  
```solidity
function addToBtclist(address[] calldata _tokens)
```  

---  

## Step 2: Set Redemption Rate (tokens/second)  

Controls the redemption flow rate for each token.  

- Defines how many tokens can be redeemed per second  
- Must be configured for each supported token  
- Helps **prevent system overload**  
- Arrays `_tokens` and `_quotas` must have **matching lengths**  
- **Calculation formula**:  
  ```
  _quotas = (uniBTC amount * 10^8) / 86400
  ```
  **Example**: To set **100 uniBTC** daily limit:  
  ```
  _quotas = (100 * 10^8) / 86400 ≈ 115740 (satoshi per second)
  ```  

### Function:  
```solidity
function setQuotaRates(address[] calldata _tokens, uint256[] calldata _quotas)
```  

---  

## Step 3: Set Maximum Redemption Cap  

Defines the **maximum amount** that can be redeemed in a single transaction.  

- Individual limits for each token type  
- **Cannot exceed** `MAX_DAILY_REDEEM_CAP` (**100 BTC**)  
- Protects against large redemption attacks  
- Must be set for all supported tokens  
- **Calculation formula**:  
  ```
  _quotas = uniBTC amount * 10^8
  ```
  **Example**: To set **10 uniBTC** max cap:  
  ```
  _quotas = 10 * 10^8 = 1000000000 (satoshi)
  ```  

### Function:  
```solidity
function setMaxQuotaForTokens(address[] calldata _tokens, uint256[] calldata _quotas)
```  

---  

## Step 4: Configure Redemption Fee Rate  

Defines the fee rate for all redemption operations.  

- **Base unit**: `10000 = 100%`  
- **Default rate**: `200 = 2%`  
- **Must be less than** `REDEEM_FEE_RATE_RANGE (10000)`  
- Applied **uniformly** to all token types  

### Function:  
```solidity
function setRedeemFeeRate(uint256 _newRate)
```  

---  

## Step 5: Configure Whitelist  

Controls access to redemption functionality.  

1. The whitelist is **enabled by default**  
2. Add approved addresses using `addToWhitelist`  
3. Only whitelisted addresses can perform redemptions when enabled  
4. **Multiple addresses** can be added in a single transaction  
5. Admin can **disable the whitelist** feature if needed  

### Functions:  
```solidity
function setWhitelistEnabled(bool _enabled)
function addToWhitelist(address[] calldata _accounts)
```

## Step 6: Configure Vault allowTargetList

This step involves configuring the Vault to allow specific contracts for redemption operations. Follow these guidelines:

### Case 1: Allow Native Token Redemption
- Call the Vault contract method `allowTarget` with parameters `[uniBTC, Redeem]`.
- This enables direct redemption of native BTC tokens.

### Case 2: Allow ERC20 Token Redemption
- Call the Vault contract method `allowTarget` with parameters `[uniBTC, ERC20]`.
- This ensures that only approved ERC20 tokens can be redeemed.

### Case 3: Allow Native and ERC20 Token Redemption
- Call the Vault contract method `allowTarget` with parameters `[uniBTC, Redeem, ERC20]`.
- This configuration allows both native BTC and ERC20 token redemptions.
