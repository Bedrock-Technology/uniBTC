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

    address public WBTC;
    address public uniBTC;

    mapping(address => uint256) public caps;
    mapping(address => bool) public paused;

    bool public redeemable;

    address public constant NATIVE_BTC = address(0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    uint8 public constant NATIVE_BTC_DECIMALS = 18;

    uint256 public constant EXCHANGE_RATE_BASE = 1e10;

    modifier whenRedeemable() {
        require(redeemable, "SYS011");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev mint uniBTC with native BTC
     */
    function mintNative() external payable {
        require(!paused[NATIVE_BTC], "SYS004");
        _mintNative(msg.sender, msg.value);
    }

    /**
     * @dev mint uniBTC with WBTC
     */
    function mint(uint256 _maxAmount) external {
        require(!paused[WBTC], "SYS003");
        _mint(WBTC, _maxAmount);
    }

    /**
     * @dev mint uniBTC with the given type of wrapped BTC
     */
    function mint(address _token, uint256 _maxAmount) external {
        require(!paused[_token], "SYS004");
        _mint(_token, _maxAmount);
    }

    /**
     * @dev burn uniBTC and redeem native BTC
     */
    function redeemNative(uint256 _maxAmount) external whenRedeemable {
        _redeemNative(msg.sender, _maxAmount);
    }

    /**
     * @dev burn uniBTC and redeem WBTC
     */
    function redeem(uint256 _maxAmount) external whenRedeemable {
        _redeem(WBTC, _maxAmount);
    }

    /**
     * @dev burn uniBTC and redeem the given type of wrapped BTC
     */
    function redeem(address _token, uint256 _maxAmount) external whenRedeemable {
        _redeem(_token, _maxAmount);
    }

    /**
     * ======================================================================================
     *
     * ADMIN
     *
     * ======================================================================================
     */
    function initialize(address _defaultAdmin, address _WBTC, address _uniBTC) initializer public {
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        require(_WBTC != address(0x0), "SYS001");
        require(_uniBTC != address(0x0), "SYS002");

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(PAUSER_ROLE, _defaultAdmin);

        WBTC = _WBTC;
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
        require(_token != address(0x0), "SYS005");

        uint8 decs = NATIVE_BTC_DECIMALS;

        if (_token != NATIVE_BTC) decs = ERC20(_token).decimals();

        require(decs == 8 || decs == 18, "SYS006");

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
     * @dev mint uniBTC with native BTC tokens
     */
    function _mintNative(address sender, uint256 _maxAmount) internal {
        (, uint256 uniBTCAmount) = _amountsNative(_maxAmount);
        require(uniBTCAmount > 0, "USR010");

        require(address(this).balance + _maxAmount <= caps[NATIVE_BTC], "USR003");

        IMintableContract(uniBTC).mint(msg.sender, uniBTCAmount);

        emit Minted(NATIVE_BTC, _maxAmount);
    }

    /**
     * @dev mint uniBTC with wrapped BTC tokens
     */
    function _mint(address _token, uint256 _maxAmount) internal {
        (, uint256 uniBTCAmount) = _amounts(_token, _maxAmount);
        require(uniBTCAmount > 0, "USR010");

        require(IERC20(_token).balanceOf(address(this)) + _maxAmount <= caps[_token], "USR003");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _maxAmount);
        IMintableContract(uniBTC).mint(msg.sender, uniBTCAmount);

        emit Minted(_token, _maxAmount);
    }

    /**
     * @dev burn uniBTC and return native BTC tokens
     */
    function _redeemNative(address sender, uint256 _maxAmount) internal {
        (uint256 actualAmount, uint256 uniBTCAmount) = _amountsNative(_maxAmount);
        require(uniBTCAmount > 0, "USR010");

        IMintableContract(uniBTC).burnFrom(msg.sender, uniBTCAmount);
        payable(sender).sendValue(actualAmount);

        emit Redeemed(NATIVE_BTC, _maxAmount);
    }

    /**
     * @dev burn uniBTC and return wrapped BTC tokens
     */
    function _redeem(address _token, uint256 _maxAmount) internal {
        (uint256 actualAmount, uint256 uniBTCAmount) = _amounts(_token, _maxAmount);
        require(uniBTCAmount > 0, "USR010");

        IMintableContract(uniBTC).burnFrom(msg.sender, uniBTCAmount);
        IERC20(_token).safeTransfer(msg.sender, actualAmount);

        emit Redeemed(_token, _maxAmount);
    }

    /**
     * @dev determine the valid native BTC amount and the corresponding uniBTC amount.
     */
    function _amountsNative(uint256 _maxAmount) internal returns (uint256, uint256) {
        uint256 uniBTCAmt = _maxAmount /EXCHANGE_RATE_BASE;
        return (uniBTCAmt * EXCHANGE_RATE_BASE, uniBTCAmt);
    }

    /**
     * @dev determine the valid wrapped BTC amount and the corresponding uniBTC amount.
     */
    function _amounts(address _token, uint256 _maxAmount) internal returns (uint256, uint256) {
        uint8 decs = ERC20(_token).decimals();
        if (decs == 8) return (_maxAmount, _maxAmount);
        if (decs == 18) {
            uint256 uniBTCAmt = _maxAmount /EXCHANGE_RATE_BASE;
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
