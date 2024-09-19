// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/ISupplyFeeder.sol";

contract SigmaSupplier is ISupplyFeeder, Initializable, AccessControlUpgradeable {
    address public constant NATIVE_BTC = address(0xbeDFFfFfFFfFfFfFFfFfFFFFfFFfFFffffFFFFFF);

    mapping(address => address[]) public tokenHolders;

    receive() external payable {
        revert("value only accepted by the Vault contract");
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Calculate the current total supply of assets for 'token'.
     */
    function totalSupply(address _token) external view returns(uint256) {
        if (_token == NATIVE_BTC) {
            return _totalSupply();
        }
        return _totalSupply(_token);
    }

    /**
     * ======================================================================================
     *
     * ADMIN FUNCTIONS
     *
     * ======================================================================================
     */

    function initialize(address _defaultAdmin) initializer public {
        __AccessControl_init();

        require(_defaultAdmin != address(0x0), "SYS001");

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /**
     * @dev set token holder addresses to track the supply of assets.
     */
    function setTokenHolders(address _token, address[] calldata _tokenHolders) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenHolders[_token] = _tokenHolders;
    }

    /**
     * ======================================================================================
     *
     * INTERNAL FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * @dev calculate the current total native token assets supplied
     *
     * TODO: Optimize, especially when multiple tokens should be considered simultaneously.
     * For example, when the supply of FBTC and FBTC1 for the Vault should be calculated and summed simultaneously.
     * NOTE: Currently, '_totalSupply' is limited to just one token.
     *
     */
    function _totalSupply() internal view returns (uint256) {
        uint256 total;
        address[] memory holders = tokenHolders[NATIVE_BTC];
        for (uint256 i = 0; i < holders.length; i++) {
            uint256 balance = holders[i].balance;
            total += balance;
        }
        return total;
    }

    /**
     * @dev calculate the current total ERC-20 token assets supplied
     *
     * TODO: Optimize, especially when multiple tokens should be considered simultaneously.
     * For example, when the supply of FBTC and FBTC1 for the Vault should be calculated and summed simultaneously.
     * NOTE: Currently, '_totalSupply' is limited to just one token.
     *
     */
    function _totalSupply(address _token) internal view returns (uint256) {
        uint256 total;
        address[] memory holders = tokenHolders[_token];
        for (uint256 i = 0; i < holders.length; i++) {
            uint256 balance = ERC20(_token).balanceOf(holders[i]);
            total += balance;
        }
        return total;
    }
}
