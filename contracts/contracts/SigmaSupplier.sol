// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/ISupplyFeeder.sol";

contract SigmaSupplier is ISupplyFeeder, Initializable, AccessControlUpgradeable {
    address public constant NATIVE_BTC = address(0xbeDFFfFfFFfFfFfFFfFfFFFFfFFfFFffffFFFFFF);

    address public vault;

    /**
     * @dev lockedTokens record the ERC-20 token addresses that supply locked assets to the Vault for DeFi profit yield.
     * 1. The KEY is the token address (native BTC or wrapped BTC token address) available in the Vault.
     * 2. The VALUE is an array of ERC-20 token addresses that supply locked assets to the Vault for DeFi profit yield.
     *
     * Note: The concept of "Locked Token" here adopts a similar concept to "Locked FBTC" originating from the
     * FBTC project: https://docs.fbtc.com/ecosystem/locked-fbtc-token
     */
    mapping(address => address[]) public lockedTokens;

    receive() external payable {
        revert("value only accepted by the Vault contract");
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Calculate the current total native token assets supplied for the Vault but locked outside the Vault for
     * DeFi profit yield
     */
    function lockedSupply() external view returns(uint256) {
        return _lockedSupply(NATIVE_BTC);
    }

    /**
     * @dev Calculate the current total wrapped token assets supplied for the Vault but locked outside the Vault for
     * DeFi profit yield
     */
    function lockedSupply(address _token) external view returns(uint256) {
        return _lockedSupply(_token);
    }

    /**
     * ======================================================================================
     *
     * ADMIN FUNCTIONS
     *
     * ======================================================================================
     */

    function initialize(address _defaultAdmin, address _vault) initializer public {
        __AccessControl_init();

        require(_defaultAdmin != address(0x0), "SYS001");
        require(_vault != address(0x0), "SYS001");

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);

        vault = _vault;
    }

    /**
     * @dev set locked token addresses to track the locked supply assets of the vault.
     */
    function setLockedTokens(address _token, address[] calldata _lockedTokens) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockedTokens[_token] = _lockedTokens;
    }

    /**
     * ======================================================================================
     *
     * INTERNAL FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * @dev calculate the current total token assets supplied for the Vault but locked outside the Vault for
     * DeFi profit yield
     */
    function _lockedSupply(address _token) internal view returns (uint256) {
        uint256 total;
        address[] memory _tokens = lockedTokens[_token];
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 balance = ERC20(_tokens[i]).balanceOf(vault);
            total += balance;
        }
        return total;
    }
}
