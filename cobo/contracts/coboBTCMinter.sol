// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IMintableContract.sol";
import "../interfaces/IVault.sol";

contract coboBTCMinter is Initializable, ReentrancyGuardUpgradeable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _defaultAdmin, address _operator, address _coboBTC, address _vault) initializer public {
        require(_coboBTC != address(0x0), "SYS001");
        require(_vault != address(0x0), "SYS001");

        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(OPERATOR_ROLE, _operator);

        coboBTC = _coboBTC;
        vault = _vault;
        uniBTC = IVault(vault).uniBTC();
    }

    /**
     * @dev coboBTC is the address of the coboBTC contract
    */
    address public coboBTC;

    /**
     * @dev vault is the address of the uniBTC vault
    */
    address public vault;

    /**
     * @dev uniBTC is the address of the uniBTC token
    */
    address public uniBTC;

    /**
     * @dev processIdx is the current index of the last processed event
    */
    uint64 public processIdx;

    /**
     * @dev eventIndexes is the array of txHashes of the events
    */
    bytes32[] public eventIndexes;

    /**
     * @dev recipients is the white list of recipients
    */
    mapping(address => bool) public recipients;

    /**
     * @dev events is the mapping of txHash to Event
    */
    mapping(bytes32 => Event) public events;

    enum EventState {
        Unused,
        Pending,
        Accepted,
        Rejected
    }

    struct Event {
        address recipient;
        uint256 amount;
        EventState state;
    }

    /**
     * @dev receive the event
    */
    function receiveEvent(address _recipient, bytes32 _txHash, uint256 _amount) public onlyRole(OPERATOR_ROLE) {
        require(_amount > 0, "USR011");
        require(_recipient != address(0), "USR011");
        require(_txHash != bytes32(0), "USR011");
        require(recipients[_recipient], "USR012");
        require(events[_txHash].recipient == address(0), "USR013");

        events[_txHash] = Event(_recipient, _amount, EventState.Pending);
        eventIndexes.push(_txHash);
        emit Received(_recipient, _txHash, _amount);
    }

    /**
     * @dev approve the event
    */
    function approveEvent() public onlyRole(ADMIN_ROLE) {
        require(processIdx < eventIndexes.length, "SYS003");

        bytes32 _txHash = eventIndexes[processIdx];
        Event storage e = events[_txHash];
        require(e.state == EventState.Pending, "USR014");

        e.state = EventState.Accepted;
        processIdx++;

        emit Accepted(e.recipient, _txHash, e.amount);
        _mint(e.recipient, e.amount);
    }

    /**
     * @dev mint the amount of uniBTC to the recipient
     * 1. mint coboBTC
     * 2. mint uniBTC with coboBTC
     * 3. transfer uniBTC to recipient
    */
    function _mint(address _recipient, uint256 _amount) internal {

        IMintableContract(coboBTC).mint(address(this), _amount);

        IVault(vault).mint(coboBTC, _amount);

        IERC20(uniBTC).safeTransfer(_recipient, _amount);
    }

    /**
     * @dev reject the event
    */
    function rejectEvent() public onlyRole(ADMIN_ROLE) {
        require(processIdx < eventIndexes.length, "SYS003");

        bytes32 _txHash = eventIndexes[processIdx];
        Event storage e = events[_txHash];
        require(e.state == EventState.Pending, "USR014");

        e.state = EventState.Rejected;
        processIdx++;
        emit Rejected(e.recipient, _txHash, e.amount);
    }

    /**
     * @dev set the recipient to allow or disallow
    */
    function setAllowRecipient(address _addr, bool allow) public onlyRole(ADMIN_ROLE) {
        recipients[_addr] = allow;
        emit RecipientChanged(_addr, allow);
    }

    /**
     * @dev events of the contract
    */
    event Received(address indexed recipient, bytes32 _txHash, uint256 _amount);
    event Accepted(address indexed recipient, bytes32 _txHash, uint256 _amount);
    event Rejected(address indexed recipient, bytes32 _txHash, uint256 _amount);
    event RecipientChanged(address indexed _addr, bool allow);
}
