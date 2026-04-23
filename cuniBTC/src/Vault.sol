// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interface/IMintableContract.sol";

contract Vault is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    using SafeERC20 for IERC20;
    using Address for address;

    address public cuniBTC;

    mapping(address => uint256) public tokenCaps;
    mapping(address => uint256) public tokenMinted;
    mapping(address => bool) public tokenPaused;

    uint256 public constant EXCHANGE_RATE_BASE = 1e10;

    mapping(address => bool) public allowedTokenList;
    mapping(address => bool) public allowedTargetList;
    bool public outOfService;

    uint256 public operatePeriod;
    uint256 public lockupPeriod;
    uint256 public startGenesis;
    uint256 public totalSupply;

    receive() external payable {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier serviceNormal() {
        require(!outOfService, "SYS011");
        _;
    }

    /**
     * @dev mint uniBTC with the given type of wrapped BTC
     */
    function mint(address _token, uint256 _amount) external serviceNormal nonReentrant {
        require(allowedTokenList[_token] && !tokenPaused[_token], "SYS002");
        _mint(msg.sender, _token, _amount);
    }

    // @dev execute a contract call that also transfers '_value' wei to '_target'
    function execute(address _target, bytes memory _data, uint256 _value)
        external
        nonReentrant
        onlyRole(OPERATOR_ROLE)
        serviceNormal
        returns (bytes memory)
    {
        require(allowedTargetList[_target], "SYS001");
        return _target.functionCallWithValue(_data, _value);
    }

    function isOperatePeriod() public view returns (bool) {
        uint256 delta = block.number - startGenesis;
        uint256 mod = delta % (operatePeriod + lockupPeriod);
        if (mod < operatePeriod) {
            return true;
        } else {
            return false;
        }
    }

    function isLockupPeriod() public view returns (bool) {
        return !isOperatePeriod();
    }

    function periodRemain() external view returns (uint256) {
        uint256 delta = block.number - startGenesis;
        uint256 mod = delta % (operatePeriod + lockupPeriod);
        if (mod < operatePeriod) {
            return operatePeriod - mod;
        } else {
            return operatePeriod + lockupPeriod - mod;
        }
    }

    /**
     * ======================================================================================
     *
     * ADMIN
     *
     * ======================================================================================
     */
    function initialize(address _defaultAdmin, address _cuniBTC, uint256 _totalSupply) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        require(_cuniBTC != address(0x0), "SYS001");
        require(_defaultAdmin != address(0x0), "SYS001");

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);

        cuniBTC = _cuniBTC;
        startGenesis = block.number;
        operatePeriod = 7200 * 7; //7day
        lockupPeriod = 7200 * 30; //30day
        totalSupply = _totalSupply;
    }

    /**
     * @dev allow the minting of a token
     */
    function allowToken(address[] memory _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _token.length; i++) {
            allowedTokenList[_token[i]] = true;
        }
        emit TokenAllowed(_token);
    }

    /**
     * @dev deny the minting of a token
     */
    function denyToken(address[] memory _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _token.length; i++) {
            allowedTokenList[_token[i]] = false;
        }
        emit TokenDenied(_token);
    }

    /**
     * @dev allow the target address
     */
    function allowTarget(address[] memory _targets) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _targets.length; i++) {
            allowedTargetList[_targets[i]] = true;
        }
        emit TargetAllowed(_targets);
    }

    /**
     * @dev deny the target address
     */
    function denyTarget(address[] memory _targets) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _targets.length; i++) {
            allowedTargetList[_targets[i]] = false;
        }
        emit TargetDenied(_targets);
    }

    /**
     * @dev a pauser pause the minting of a token
     */
    function pauseToken(address[] memory _tokens) external onlyRole(PAUSER_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenPaused[_tokens[i]] = true;
        }
        emit TokenPaused(_tokens);
    }

    /**
     * @dev a pauser unpause the minting of a token
     */
    function unpauseToken(address[] memory _tokens) external onlyRole(PAUSER_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenPaused[_tokens[i]] = false;
        }
        emit TokenUnpaused(_tokens);
    }

    /**
     * @dev START ALL SERVICE
     */
    function startService() external onlyRole(PAUSER_ROLE) {
        outOfService = false;
        emit StartService();
    }

    /**
     * @dev STOP ALL SERVICE
     */
    function stopService() external onlyRole(PAUSER_ROLE) {
        outOfService = true;
        emit StopService();
    }

    function setPeriod(uint256 _start, uint256 _operatePeriod, uint256 _lockupPeriod)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_operatePeriod + _lockupPeriod > 0, "USR018");
        require(_start <= block.number, "USR019");
        startGenesis = _start;
        operatePeriod = _operatePeriod;
        lockupPeriod = _lockupPeriod;
        emit PeriodSet(_start, _operatePeriod, _lockupPeriod);
    }

    /**
     * @dev set cap for a specific type of wrapped BTC
     */
    function setCap(address _token, uint256 _cap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_token != address(0x0), "SYS003");
        uint8 decs = ERC20(_token).decimals();
        require(decs == 8 || decs == 18, "SYS004");
        tokenCaps[_token] = _cap;
        emit CapSet(_token, _cap);
    }

    /**
     * @dev set total supply for a specific type of wrapped BTC
     */
    function setTotalSupply(uint256 _totalSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        totalSupply = _totalSupply;
        emit TotalSupplySet(totalSupply);
    }

    /**
     * ======================================================================================
     *
     * INTERNAL
     *
     * ======================================================================================
     */

    /**
     * @dev mint cuniBTC with wrapped BTC tokens
     */
    function _mint(address _sender, address _token, uint256 _amount) internal {
        (, uint256 cuniBTCAmount) = _amounts(_token, _amount);
        require(cuniBTCAmount > 0, "USR010");

        if (tokenCaps[_token] != 0) {
            require(tokenMinted[_token] + _amount <= tokenCaps[_token], "SYS003");
        }
        require(IERC20(cuniBTC).totalSupply() + cuniBTCAmount <= totalSupply, "SYS004");
        tokenMinted[_token] += _amount;

        IERC20(_token).safeTransferFrom(_sender, address(this), _amount);
        IMintableContract(cuniBTC).mint(_sender, cuniBTCAmount);

        emit Minted(_sender, _token, _amount);
    }

    /**
     * @dev determine the valid wrapped BTC amount and the corresponding cuniBTC amount.
     */
    function _amounts(address _token, uint256 _amount) internal view returns (uint256, uint256) {
        uint8 decs = ERC20(_token).decimals();
        if (decs == 8) return (_amount, _amount);
        if (decs == 18) {
            uint256 uniBTCAmt = _amount / EXCHANGE_RATE_BASE;
            return (uniBTCAmt * EXCHANGE_RATE_BASE, uniBTCAmt);
        }
        revert("USR010");
    }

    /**
     * ======================================================================================
     *
     * EVENTS
     *
     * ======================================================================================
     */
    event Minted(address sender, address token, uint256 amount);
    event TokenPaused(address[] token);
    event CapSet(address token, uint256 cap);
    event TotalSupplySet(uint256 totalSupply);
    event TokenUnpaused(address[] token);
    event TokenAllowed(address[] token);
    event TokenDenied(address[] token);
    event TargetAllowed(address[] token);
    event TargetDenied(address[] token);
    event PeriodSet(uint256 start, uint256 operatePeriod, uint256 lockupPeriod);
    event StartService();
    event StopService();
}
