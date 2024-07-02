// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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

    mapping(address => uint256) public caps;
    mapping(address => bool) public paused;

    uint private constant MULTIPLIER = 1e24;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    /**
     * @dev mint uniBTC with WBTC
     * @param _amount the quantity of WBTC for exchange of uniBTC
     * @return minted the quantity of minted uniBTC.
     */
    function mint(uint256 _amount) external returns (uint256 minted) {
        require(!paused[WBTC], "SYS003");
        return _mint(WBTC, _amount);
    }

    /**
     * @dev mint uniBTC with the given type of wrapped BTC
     * @param _token the wrapped BTC for exchange of uniBTC
     * @param _amount the quantity of wrapped BTC for exchange of uniBTC
     * @return minted the quantity of minted uniBTC.
     */
    function mint(address _token, uint256 _amount) external returns (uint256 minted) {
        require(!paused[_token], "SYS004");
        return _mint(_token, _amount);
    }

    /**
     * @dev burn uniBTC and redeem WBTC
     * @param _amount the quantity of WBTC to redeem
     * @return burned the quantity of uniBTC burned
     */
    function redeem(uint256 _amount) external returns (uint256 burned) {
        return _redeem(WBTC, _amount);
    }

    /**
     * @dev burn uniBTC and redeem the given type of wrapped BTC
     * @param _token the wrapped BTC to redeem
     * @param _amount the quantity wrapped BTC to redeem
     * @return burned the quantity of uniBTC burned
     */
    function redeem(address _token, uint256 _amount) external returns (uint256 burned) {
        return _redeem(_token, _amount);
    }

    /**
     * @dev calculate the exchange ratio of uniBTC to xBTC (wrapped BTC), which conforms to the proportion `1 uniBTC = 1 xBTC`.
     * To calculate the wrapped BTC amount equivalent to the specified uniBTC amount, use the following formula:
     * xBTCAmt = uniBTCAmt * r / 1e24, where r stands for the result of exchangeRatio(xBTC).
     */
    function exchangeRatio(address _token) internal returns (uint256) {
        uint256 xBTCDecimals = ERC20(_token).decimals();
        uint256 uniBTCDecimals = ERC20(uniBTC).decimals();
        return 10**xBTCDecimals * MULTIPLIER / 10**uniBTCDecimals;
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
     * @dev set cap for a specific type of wrapped BTC
     */
    function setCap(address _token, uint256 _cap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_token != address(0x0), "SYS005");
        require(_exchangeRatio(_token) > 0, "SYS006");
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
    function _mint(address _token, uint256 _amount) internal returns (uint256) {
        require(IERC20(_token).balanceOf(address(this)) + _amount <= caps[_token], "USR003");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 uniBTCAmt = _uniBTCAmt(_token, _amount);
        IMintableContract(uniBTC).mint(msg.sender, uniBTCAmt);
        emit Minted(_token, _amount);

        return uniBTCAmt;
    }

    /**
     * @dev redeem internal
     */
    function _redeem(address _token, uint256 _amount) internal returns (uint256) {
        IERC20(_token).safeTransfer(msg.sender, _amount);

        uint256 uniBTCAmt = _uniBTCAmt(_token, _amount);
        IMintableContract(uniBTC).burnFrom(msg.sender, uniBTCAmt);
        emit Redeemed(_token, _amount);

        return uniBTCAmt;
    }

    /**
     * @dev calculate the equivalent uniBTC amount to mint or burn, which conforms to the proportion `1 xBTC = 1 uniBTC`
     */
    function _uniBTCAmt(address _token, uint256 _amount) internal returns (uint256) {
        uint256 r = _exchangeRatio(_token);
        return _amount * r / MULTIPLIER;
    }

    /**
     * @dev calculate the exchange ratio of xBTC (wrapped BTC) to uniBTC, which conforms to the proportion `1 xBTC = 1 uniBTC`
     */
    function _exchangeRatio(address _token) internal returns (uint256) {
        uint256 uniBTCDecimals = ERC20(uniBTC).decimals();
        uint256 xBTCDecimals = ERC20(_token).decimals();
        return 10**uniBTCDecimals * MULTIPLIER / 10**xBTCDecimals;
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
}
