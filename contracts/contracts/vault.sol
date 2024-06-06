// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

import "../interfaces/iface.sol";

contract Vault is Initializable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    using SafeERC20 for IERC20;

    address public WBTC;
    address public uniBTC;

    mapping(address => uint256) public caps;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*
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
    */

    /**
     * @dev mint uniBTC with WBTC
     */
    function mint(uint256 _amount) external whenNotPaused {
        _mint(WBTC, _amount);
    }

    /**
     * @dev mint uniBTC with give types of wrapped BTC
     */
    function mint(address _token, uint256 _amount) external whenNotPaused {
        _mint(_token, _amount);
    }

    /**
     * ======================================================================================
     *
     * ADMIN
     *
     * ======================================================================================
     */

    /**
     * @dev UPDATE(20240606):  to set initial cap
     */
    function initializeV2() reinitializer(2) public {
        caps[WBTC] = 2000 * 1e8;
    } 

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }


    /**
     * @dev set cap for a specific type of wrapped BTC
     */
    function setCap(address _token, uint256 _cap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_token != address(0x0), "invalid token address");
        require(ERC20(_token).decimals() == 8, "incorrect decimals");
        caps[_token] = _cap;
    }

    /**
     * @dev withdraw token
     */
    function adminWithdraw(address _token, uint256 _amount, address _target) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_token).safeTransfer(_target, _amount);
        emit Withdrawed(_token, _amount, _target);
    }

    /**
     * ======================================================================================
     *
     * INTERNAL
     *
     * ======================================================================================
     */
    /**
     * @dev mint internal 
     */
    function _mint(address _token, uint256 _amount) internal {
        require(IERC20(_token).balanceOf(address(this)) + _amount <= caps[_token], "insufficient quota");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IMintableContract(uniBTC).mint(msg.sender, _amount);
        emit Minted(_token, _amount);
    }

    /**
     * ======================================================================================
     *
     * EVENTS
     *
     * ======================================================================================
     */
    event Withdrawed(address token, uint256 amount, address target);
    event Minted(address token, uint256 amount);
}
