// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/iface.sol";

contract Vault is Initializable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    using SafeERC20 for IERC20;
    using Address for address payable;

    address private _DEPRECATED_WBTC_;
    address public uniBTC;

    mapping(address => uint256) public caps;
    mapping(address => bool) public paused;

    bool public redeemable;

    address public constant NATIVE_BTC = address(0xbeDFFfFfFFfFfFfFFfFfFFFFfFFfFFffffFFFFFF);
    uint8 public constant NATIVE_BTC_DECIMALS = 18;

    uint256 public constant EXCHANGE_RATE_BASE = 1e10;

    modifier whenRedeemable() {
        require(redeemable, "SYS009");
        _;
    }

    receive() external payable {
        revert("value only accepted by the mint function");
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev mint uniBTC with native BTC
     */
    function mint() external payable {
        require(!paused[NATIVE_BTC], "SYS002");
        _mint(msg.sender, msg.value);
    }

    /**
     * @dev mint uniBTC with the given type of wrapped BTC
     */
    function mint(address _token, uint256 _amount) external {
        require(!paused[_token], "SYS002");
        _mint(msg.sender, _token, _amount);
    }

    /**
     * @dev burn uniBTC and redeem native BTC
     */
    function redeem(uint256 _amount) external nonReentrant whenRedeemable {
        _redeem(msg.sender, _amount);
    }

    /**
     * @dev burn uniBTC and redeem the given type of wrapped BTC
     */
    function redeem(address _token, uint256 _amount) external whenRedeemable {
        _redeem(msg.sender, _token, _amount);
    }

    /**
     * ======================================================================================
     *
     * ADMIN
     *
     * ======================================================================================
     */
    function initialize(address _defaultAdmin, address _uniBTC) initializer public {
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        require(_uniBTC != address(0x0), "SYS001");

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(PAUSER_ROLE, _defaultAdmin);

        uniBTC = _uniBTC;
    }

    /**
     * @dev a pauser pause the minting of a token
     */
    function pauseToken(address _token) public onlyRole(PAUSER_ROLE) {
        paused[_token] = true;
        emit TokenPaused(_token);
    }

    /**
     * @dev a pauser unpause the minting of a token
     */
    function unpauseToken(address _token) public onlyRole(PAUSER_ROLE) {
        paused[_token] = false;
        emit TokenUnpaused(_token);
    }

    /**
     * @dev enable or disable redemption feature
     */
    function toggleRedemption() external onlyRole(DEFAULT_ADMIN_ROLE) {
        redeemable = !redeemable;
        if (redeemable) {
            emit RedemptionOn();
        } else {
            emit RedemptionOff();
        }
    }

    /**
     * @dev set cap for a specific type of wrapped BTC
     */
    function setCap(address _token, uint256 _cap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_token != address(0x0), "SYS003");

        uint8 decs = NATIVE_BTC_DECIMALS;

        if (_token != NATIVE_BTC) decs = ERC20(_token).decimals();

        require(decs == 8 || decs == 18, "SYS004");

        caps[_token] = _cap;
    }

    /**
     * @dev withdraw native BTC
     */
    function adminWithdraw(uint256 _amount, address _target) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        emit Withdrawed(NATIVE_BTC, _amount, _target);
        payable(_target).sendValue(_amount);
    }

    /**
     * @dev withdraw wrapped BTC
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
     * @dev mint uniBTC with native BTC tokens
     */
    function _mint(address _sender, uint256 _amount) internal {
        (, uint256 uniBTCAmount) = _amounts(_amount);
        require(uniBTCAmount > 0, "USR010");

        require(address(this).balance <= caps[NATIVE_BTC], "USR003");

        IMintableContract(uniBTC).mint(_sender, uniBTCAmount);

        emit Minted(NATIVE_BTC, _amount);
    }

    /**
     * @dev mint uniBTC with wrapped BTC tokens
     */
    function _mint(address _sender, address _token, uint256 _amount) internal {
        (, uint256 uniBTCAmount) = _amounts(_token, _amount);
        require(uniBTCAmount > 0, "USR010");

        require(IERC20(_token).balanceOf(address(this)) + _amount <= caps[_token], "USR003");

        IERC20(_token).safeTransferFrom(_sender, address(this), _amount);
        IMintableContract(uniBTC).mint(_sender, uniBTCAmount);

        emit Minted(_token, _amount);
    }

    /**
     * @dev burn uniBTC and return native BTC tokens
     */
    function _redeem(address _sender, uint256 _amount) internal {
        (uint256 actualAmount, uint256 uniBTCAmount) = _amounts(_amount);
        require(uniBTCAmount > 0, "USR010");

        IMintableContract(uniBTC).burnFrom(_sender, uniBTCAmount);
        emit Redeemed(NATIVE_BTC, _amount);

        payable(_sender).sendValue(actualAmount);
    }

    /**
     * @dev burn uniBTC and return wrapped BTC tokens
     */
    function _redeem(address _sender, address _token, uint256 _amount) internal {
        (uint256 actualAmount, uint256 uniBTCAmount) = _amounts(_token, _amount);
        require(uniBTCAmount > 0, "USR010");

        IMintableContract(uniBTC).burnFrom(_sender, uniBTCAmount);
        IERC20(_token).safeTransfer(_sender, actualAmount);

        emit Redeemed(_token, _amount);
    }

    /**
     * @dev determine the valid native BTC amount and the corresponding uniBTC amount.
     */
    function _amounts(uint256 _amount) internal returns (uint256, uint256) {
        uint256 uniBTCAmt = _amount /EXCHANGE_RATE_BASE;
        return (uniBTCAmt * EXCHANGE_RATE_BASE, uniBTCAmt);
    }

    /**
     * @dev determine the valid wrapped BTC amount and the corresponding uniBTC amount.
     */
    function _amounts(address _token, uint256 _amount) internal returns (uint256, uint256) {
        uint8 decs = ERC20(_token).decimals();
        if (decs == 8) return (_amount, _amount);
        if (decs == 18) {
            uint256 uniBTCAmt = _amount /EXCHANGE_RATE_BASE;
            return (uniBTCAmt * EXCHANGE_RATE_BASE, uniBTCAmt);
        }
        return (0, 0);
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
    event Redeemed(address token, uint256 amount);
    event TokenPaused(address token);
    event TokenUnpaused(address token);
    event RedemptionOn();
    event RedemptionOff();
}
