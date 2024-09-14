// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../interfaces/IMintableContract.sol";
import "../../interfaces/Ivault.sol";

contract coboBTCMinter is Pausable, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;
    using Address for address payable;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address public coboBTC;
    address public vault; //uniBTC vault

    //processIdx is the current index of the last processed event
    uint64 public processIdx;
    bytes32[] public eventIndexes; // txHash array
    mapping(address => bool) public recipients; //recipients white list
    mapping(bytes32 => Event) public events; // txHash => Event

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

    event Received(address indexed recipient, bytes32 _txHash, uint256 _amount);
    event Accepted(address indexed recipient, bytes32 _txHash, uint256 _amount);
    event Rejected(address indexed recipient, bytes32 _txHash, uint256 _amount);
    event RecipientChanged(address indexed _addr, bool allow);

    receive() external payable {}

    constructor(address _coboBTC, address _uniBTCVault) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);

        coboBTC = _coboBTC;
        vault = _uniBTCVault;
    }

    function receiveEvent(
        address _recipient,
        bytes32 _txHash,
        uint256 _amount
    ) public onlyRole(OPERATOR_ROLE) {
        require(_amount > 0, "USR001");
        require(_recipient != address(0), "USR002");
        require(_txHash != bytes32(0), "USR003");
        
        require(recipients[_recipient], "USR004");
        require(events[_txHash].recipient == address(0), "USR005");

        events[_txHash] = Event(_recipient, _amount, EventState.Pending);
        eventIndexes.push(_txHash);
        emit Received(_recipient, _txHash, _amount);
    }

    function acceptEvent() public onlyRole(ADMIN_ROLE) {
        require(processIdx < eventIndexes.length, "USR0011");

        bytes32 _txHash = eventIndexes[processIdx];
        Event storage e = events[_txHash];
        require(e.state == EventState.Pending, "USR012");

        _mint(e.recipient, e.amount);
        e.state = EventState.Accepted;

        emit Accepted(e.recipient, _txHash, e.amount);
        processIdx++;
    }

    function _mint(address recipient, uint256 amount) internal {
        // 1. mint coboBTC to recipient
        IMintableContract(coboBTC).mint(recipient, amount);

        // 2. Approve 'amount' coboBTC to this contract and transfer
        IERC20 token = IERC20(coboBTC);
        if (token.allowance(recipient, address(this)) < amount) {
            token.approve(address(this), amount);
        }
        token.transferFrom(recipient, address(this), amount);

        // 3. mint uniBTC with coboBTC.
        bytes memory data;
        data = abi.encodeWithSelector(IMintableContract.mint.selector, coboBTC, amount);
        IVault(vault).execute(vault, data, 0);
    }

    function _burn(uint256 amount) internal {
        // todo burn uniBTC
    }

    function rejectEvent() public onlyRole(ADMIN_ROLE) {
        require(processIdx < eventIndexes.length, "USR021");

        bytes32 _txHash = eventIndexes[processIdx];
        Event storage e = events[_txHash];
        require(e.state == EventState.Pending, "USR022");

        e.state = EventState.Rejected;
        emit Rejected(e.recipient, _txHash, e.amount);
        processIdx++;
    }

    function setAllowRecipient(
        address _addr,
        bool allow
    ) public onlyRole(ADMIN_ROLE) {
        recipients[_addr] = allow;
        emit RecipientChanged(_addr, allow);
    }
}
