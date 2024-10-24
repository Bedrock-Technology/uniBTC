// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/ISupplyFeeder.sol";


/**
 * Sigma Aggregation of same token but different state 
                 ┌────────────────┐                                 
                 │   Leading      │                                 
                 │   Token        │                                 
                 │                │                                 
                 │                │                                 
                 └────────────────┘                                 
                 ┌────────────────┐                                 
                 │   Leading      │                                 
                 │   Token        │                                 
                 │                │                                 
                 │                │                                 
                 └────────────────┘                                 
                 ┌────────────────┐                                 
                 │   Leading      │                                 
                 │   Token(FBTC)  │                                 
             ┌──►│                ◄───────┐                         
             │   │                │       │                         
             │   └────────────────┘       │                        
             │                            │                         
             │                            │                         
             │                            │                         
    ┌────────┼──────┐            ┌────────┼─────────┐               
    │Pool1          │            │Pool2             │               
    │               │            │                  │               
    │F0: 0x         │            │F1:0x             │               
    │Holders: A,B,C │            │Holders: D,E,F    │               
    └───────────────┘            └──────────────────┘               
 */    
contract Sigma is ISupplyFeeder, Initializable, AccessControlUpgradeable {
    address public constant NATIVE_BTC = address(0xbeDFFfFfFFfFfFfFFfFfFFFFfFFfFFffffFFFFFF);
    uint8 public constant L2_BTC_DECIMAL = 18;

                                                                    
    /// @dev A Pool represents a group of token holders of the same token.
    struct Pool {
        address token;
        address[] holders;
    }

    /// @dev A list of leadingTokens stores all the tokens that lead groups of Pools.
    address[] public leadingTokens;

    /**
     * @dev A mapping of tokenHolders stores the token holders for each token.
     * The key is the leading token address, and the value is an array of Pools.
     * The leading token and all corresponding tokens in the Pool array must have the same decimals.
     */
    mapping(address => Pool[]) public tokenHolders;

    /**
     * ======================================================================================
     *
     * SYSTEM SETTINGS
     *
     * ======================================================================================
     */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {
        revert("value not accepted");
    }

    function initialize(address _defaultAdmin) initializer public {
        __AccessControl_init();

        require(_defaultAdmin != address(0x0), "SYS001");

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /**
     * ======================================================================================
     *
     * VIEW FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * @dev Calculate the current total supply of assets for '_leadingToken'.
     */
    function totalSupply(address _leadingToken) external view returns (uint256) {
        require(tokenHolders[_leadingToken].length > 0, "USR018");
        return _totalSupply(_leadingToken);
    }

    /**
     * @dev A helper function to retrieve the token holders for a specified '_leadingToken'.
     */
    function getTokenHolders(address _leadingToken) external view returns (Pool[] memory) {
        return tokenHolders[_leadingToken];
    }

    /**
     * @dev A helper function to list all tokens that lead groups of Pools.
     * The token address returned here is the key in the tokenHolders mapping
     * and can be used to retrieve the token holders via 'getTokenHolders'.
     */
    function ListLeadingTokens() external view returns (address[] memory) {
        return leadingTokens;
    }

    /**
     * ======================================================================================
     *
     * ADMIN FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * @dev Set holders to track the total supply of assets, which must have the same decimals.
     */
    function setTokenHolders(address _leadingToken, Pool[] calldata _pools) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // precheck
        require(_haveSameDecimals(_leadingToken, _pools), "SYS010");

        // remove previous setting
        delete tokenHolders[_leadingToken];

        // set new token aggregation
        for (uint256 i = 0; i < _pools.length; i++) {
            tokenHolders[_leadingToken].push(_pools[i]);
        }
        emit TokenHoldersSet(_leadingToken, _pools);

        // set new leading tokens
        for (uint256 i = 0; i < leadingTokens.length; i++) {
            if (leadingTokens[i] == _leadingToken) {
                return;
            }
        }
        leadingTokens.push(_leadingToken);
    }

    /**
     * ======================================================================================
     *
     * INTERNAL FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * @dev Calculate the current total assets (native assets and ERC-20 assets) supplied.
     */
    function _totalSupply(address _leadingToken) internal view returns (uint256) {
        uint256 total;
        Pool[] memory pools = tokenHolders[_leadingToken];
        for (uint256 i = 0; i < pools.length; i++) {
            address token = pools[i].token;
            address[] memory holders = pools[i].holders;

            // aggregation native token and ERC20 token
            if (token == NATIVE_BTC) {
                for (uint256 j = 0; j < holders.length; j++) {
                    uint256 balance = holders[j].balance;
                    total += balance;
                }
            } else {
                for (uint256 j = 0; j < holders.length; j++) {
                    uint256 balance = ERC20(token).balanceOf(holders[j]);
                    total += balance;
                }
            }
        }
        return total;
    }

    /**
    * @dev Check if all tokens in the pools have the same decimals as the leading token.
     */
    function _haveSameDecimals(address _leadingToken, Pool[] calldata _pools) internal view returns (bool) {
        uint8 decimals = _leadingToken == NATIVE_BTC ? L2_BTC_DECIMAL : ERC20(_leadingToken).decimals();
        for (uint256 i = 0; i < _pools.length; i++) {
            address poolToken = _pools[i].token;
            if (poolToken == NATIVE_BTC) {
                if (decimals != L2_BTC_DECIMAL) {
                    return false;
                }
            } else {
                if (ERC20(poolToken).decimals() != decimals) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * ======================================================================================
     *
     * EVENTS
     *
     * ======================================================================================
     */
    event TokenHoldersSet(address leadingToken, Pool[] pools);
}
