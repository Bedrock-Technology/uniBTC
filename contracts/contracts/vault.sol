// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/iface.sol";

contract Vault is Initializable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    using SafeERC20 for IERC20;

    address public WBTC;
    address public uniBTC;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _defaultAdmin, address _WBTC, address _uniBTC) initializer public {
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        require(_WBTC != address(0x0), "invalid WBTC address");
        require(_uniBTC != address(0x0), "invalid uniBTC address");

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(PAUSER_ROLE, _defaultAdmin);

        WBTC = _WBTC;
        uniBTC = _uniBTC;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev mint uniBTC with WBTC
     */
    function mint(uint256 _amount) external whenNotPaused {
        IERC20(WBTC).safeTransferFrom(msg.sender, address(this), _amount);
        IMintableContract(uniBTC).mint(msg.sender, _amount);
    }
}
