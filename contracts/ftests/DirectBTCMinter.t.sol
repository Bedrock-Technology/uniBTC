// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DirectBTCMinter} from "../contracts/proxies/stateful/directBTC/DirectBTCMinter.sol";
import {directBTC} from "../contracts/proxies/stateful/directBTC/directBTC.sol";
import {uniBTC} from "../contracts/uniBTC.sol";
import {Vault} from "../contracts/Vault.sol";
import {ISupplyFeeder} from "../interfaces/ISupplyFeeder.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

// Mock supply feeder for testing
contract MockSupplyFeeder is ISupplyFeeder {
    function totalSupply(address) external pure override returns (uint256) {
        return 0; // Return 0 to avoid cap restrictions
    }
}

contract DirectBTCMinterTest is Test {
    DirectBTCMinter public minter;
    directBTC public directBTCToken;
    uniBTC public uniBTCToken;
    Vault public vault;
    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public minterProxy;
    TransparentUpgradeableProxy public directBTCProxy;
    TransparentUpgradeableProxy public uniBTCProxy;
    TransparentUpgradeableProxy public vaultProxy;
    
    address public owner;
    address public operator;
    address public approver;
    address public user1;
    address public user2;
    
    bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");
    bytes32 public constant L1_MINTER_ROLE = keccak256("L1_MINTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    event Received(address indexed recipient, bytes32 _txHash, uint256 _amount);
    event Accepted(address indexed recipient, bytes32 _txHash, uint256 _amount);
    event Rejected(address indexed recipient, bytes32 _txHash, uint256 _amount);
    event RecipientChanged(address indexed _addr, bool allow);
    
    function setUp() public {
        // Setup accounts
        owner = vm.addr(0x1);
        operator = vm.addr(0x2);
        approver = vm.addr(0x3);
        user1 = vm.addr(0x4);
        user2 = vm.addr(0x5);
        
        vm.startPrank(owner);
        
        // Deploy ProxyAdmin
        proxyAdmin = new ProxyAdmin();
        
        // Deploy directBTC implementation and proxy
        directBTC directBTCImpl = new directBTC();
        directBTCProxy = new TransparentUpgradeableProxy(
            address(directBTCImpl),
            address(proxyAdmin),
            abi.encodeCall(directBTCImpl.initialize, (owner, owner))
        );
        directBTCToken = directBTC(payable(directBTCProxy));
        
        // Deploy uniBTC implementation and proxy
        uniBTC uniBTCImpl = new uniBTC();
        uniBTCProxy = new TransparentUpgradeableProxy(
            address(uniBTCImpl),
            address(proxyAdmin),
            abi.encodeCall(uniBTCImpl.initialize, (owner, owner, new address[](0)))
        );
        uniBTCToken = uniBTC(payable(uniBTCProxy));
        
        // Deploy Vault implementation and proxy
        Vault vaultImpl = new Vault();
        vaultProxy = new TransparentUpgradeableProxy(
            address(vaultImpl),
            address(proxyAdmin),
            abi.encodeCall(vaultImpl.initialize, (owner, address(uniBTCToken)))
        );
        vault = Vault(payable(vaultProxy));
        
        // Set up a mock supply feeder for the vault
        MockSupplyFeeder mockSupplyFeeder = new MockSupplyFeeder();
        vault.setSupplyFeeder(address(mockSupplyFeeder));
        
        // Deploy DirectBTCMinter implementation and proxy
        DirectBTCMinter minterImpl = new DirectBTCMinter();
        minterProxy = new TransparentUpgradeableProxy(
            address(minterImpl),
            address(proxyAdmin),
            abi.encodeCall(minterImpl.initialize, (owner, address(directBTCToken), address(vault), address(uniBTCToken)))
        );
        minter = DirectBTCMinter(address(minterProxy));
        
        // Grant roles
        minter.grantRole(APPROVER_ROLE, approver);
        minter.grantRole(L1_MINTER_ROLE, operator);
        
        // Grant minter role to DirectBTCMinter on directBTC token
        directBTCToken.grantRole(MINTER_ROLE, address(minter));
        
        // Grant minter role to Vault on uniBTC token (Vault needs to mint uniBTC)
        uniBTCToken.grantRole(MINTER_ROLE, address(vault));
        
        // Set up caps for directBTC token to avoid USR003 error
        vault.setCap(address(directBTCToken), 1000000e8); // 1M directBTC cap
        
        // Allow directBTC token in Vault
        address[] memory allowedTokens = new address[](1);
        allowedTokens[0] = address(directBTCToken);
        vault.allowToken(allowedTokens);
        
        // Add recipients to whitelist
        minter.setRecipient(user1, true);
        minter.setRecipient(user2, true);
        
        vm.stopPrank();
    }
    
    function testInitialization() public {
        assertEq(minter.directBTC(), address(directBTCToken));
        assertEq(minter.vault(), address(vault));
        assertEq(minter.uniBTC(), address(uniBTCToken));
        assertTrue(minter.hasRole(minter.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(minter.hasRole(APPROVER_ROLE, approver));
        assertTrue(minter.hasRole(L1_MINTER_ROLE, operator));
    }
    
    function testReceiveEvent() public {
        bytes32 txHash = keccak256("test_tx");
        uint256 amount = 1e8; // directBTC uses 8 decimals
        
        vm.prank(operator);
        vm.expectEmit(true, true, false, true);
        emit Received(user1, txHash, amount);
        
        minter.receiveEvent(user1, txHash, amount);
        
        // Check event was stored
        (address recipient, uint256 storedAmount, DirectBTCMinter.EventState state) = minter.receivedEvents(txHash);
        assertEq(recipient, user1);
        assertEq(storedAmount, amount);
        assertEq(uint256(state), uint256(DirectBTCMinter.EventState.Pending));
        
        // Check txHash was added to eventIndexes
        assertEq(minter.eventIndexes(0), txHash);
    }
    
    function testReceiveEventOnlyOperator() public {
        bytes32 txHash = keccak256("test_tx");
        uint256 amount = 1e8;
        
        vm.prank(user1);
        vm.expectRevert();
        minter.receiveEvent(user1, txHash, amount);
    }
    
    function testReceiveEventInvalidRecipient() public {
        bytes32 txHash = keccak256("test_tx");
        uint256 amount = 1e8;
        
        vm.prank(operator);
        vm.expectRevert("USR011");
        minter.receiveEvent(address(0), txHash, amount);
    }
    
    function testReceiveEventInvalidAmount() public {
        bytes32 txHash = keccak256("test_tx");
        
        vm.prank(operator);
        vm.expectRevert("USR011");
        minter.receiveEvent(user1, txHash, 0);
    }
    
    function testReceiveEventInvalidTxHash() public {
        uint256 amount = 1e8;
        
        vm.prank(operator);
        vm.expectRevert("USR011");
        minter.receiveEvent(user1, bytes32(0), amount);
    }
    
    function testReceiveEventDuplicateTxHash() public {
        bytes32 txHash = keccak256("test_tx");
        uint256 amount = 1e8;
        
        vm.startPrank(operator);
        minter.receiveEvent(user1, txHash, amount);
        
        vm.expectRevert("USR013");
        minter.receiveEvent(user1, txHash, amount);
        vm.stopPrank();
    }
    
    function testNextPendingEvent() public {
        // Add multiple events
        vm.startPrank(operator);
        minter.receiveEvent(user1, keccak256("tx1"), 1e8);
        minter.receiveEvent(user2, keccak256("tx2"), 2e8);
        vm.stopPrank();
        
        // Check next pending event
        (bytes32 txHash, DirectBTCMinter.Event memory eventData) = minter.nextPendingEvent();
        assertEq(txHash, keccak256("tx1"));
        assertEq(eventData.recipient, user1);
        assertEq(eventData.amount, 1e8);
        assertEq(uint256(eventData.state), uint256(DirectBTCMinter.EventState.Pending));
        
        // Approve first event
        vm.prank(approver);
        minter.approveEvent(keccak256("tx1"));
        
        // Check next pending event should be the second one
        (txHash, eventData) = minter.nextPendingEvent();
        assertEq(txHash, keccak256("tx2"));
        assertEq(eventData.recipient, user2);
        assertEq(eventData.amount, 2e8);
    }
    
    function testApproveEvent() public {
        bytes32 txHash = keccak256("test_tx");
        uint256 amount = 1e8;
        
        // Add event
        vm.prank(operator);
        minter.receiveEvent(user1, txHash, amount);
        
        // Check initial balance
        uint256 initialBalance = uniBTCToken.balanceOf(user1);
        
        // Approve event
        vm.prank(approver);
        // Don't check for specific events, just ensure the function succeeds
        minter.approveEvent(txHash);
        
        // Check event status
        (, , DirectBTCMinter.EventState state) = minter.receivedEvents(txHash);
        assertEq(uint256(state), uint256(DirectBTCMinter.EventState.Accepted));
        
        // Check uniBTC tokens were minted to user
        assertEq(uniBTCToken.balanceOf(user1), initialBalance + amount);
        
        // Check processIdx was incremented
        assertEq(minter.processIdx(), 1);
    }
    
    function testApproveEventOnlyApprover() public {
        bytes32 txHash = keccak256("test_tx");
        uint256 amount = 1e8;
        
        // Add event
        vm.prank(operator);
        minter.receiveEvent(user1, txHash, amount);
        
        // Try to approve as non-approver
        vm.prank(user1);
        vm.expectRevert();
        minter.approveEvent(txHash);
    }
    
    function testApproveEventWrongHash() public {
        bytes32 txHash = keccak256("test_tx");
        bytes32 wrongHash = keccak256("wrong_tx");
        uint256 amount = 1e8;
        
        // Add event
        vm.prank(operator);
        minter.receiveEvent(user1, txHash, amount);
        
        vm.prank(approver);
        vm.expectRevert("USR015");
        minter.approveEvent(wrongHash);
    }
    
    function testApproveEventRecipientNotWhitelisted() public {
        bytes32 txHash = keccak256("test_tx");
        uint256 amount = 1e8;
        address nonWhitelistedUser = vm.addr(0x99);
        
        // Add recipient to whitelist first
        vm.prank(approver);
        minter.setRecipient(nonWhitelistedUser, true);
        
        // Add event
        vm.prank(operator);
        minter.receiveEvent(nonWhitelistedUser, txHash, amount);
        
        // Remove recipient from whitelist
        vm.prank(approver);
        minter.setRecipient(nonWhitelistedUser, false);
        
        // Try to approve - should fail
        vm.prank(approver);
        vm.expectRevert("USR012");
        minter.approveEvent(txHash);
    }
    
    function testApproveEventAlreadyProcessed() public {
        bytes32 txHash1 = keccak256("test_tx_1");
        bytes32 txHash2 = keccak256("test_tx_2");
        uint256 amount = 1e8;
        
        // Add two events
        vm.prank(operator);
        minter.receiveEvent(user1, txHash1, amount);
        
        vm.prank(operator);
        minter.receiveEvent(user1, txHash2, amount);
        
        // Approve first event
        vm.prank(approver);
        minter.approveEvent(txHash1);
        
        // Try to approve first event again - should fail because it's already processed
        vm.prank(approver);
        vm.expectRevert("USR015");
        minter.approveEvent(txHash1);
    }
    
    function testRejectEvent() public {
        bytes32 txHash = keccak256("test_tx");
        uint256 amount = 1e8;
        
        // Add event
        vm.prank(operator);
        minter.receiveEvent(user1, txHash, amount);
        
        // Check initial balance
        uint256 initialBalance = uniBTCToken.balanceOf(user1);
        
        // Reject event
        vm.prank(approver);
        vm.expectEmit(true, true, false, true);
        emit Rejected(user1, txHash, amount);
        
        minter.rejectEvent(txHash);
        
        // Check event status
        (, , DirectBTCMinter.EventState state) = minter.receivedEvents(txHash);
        assertEq(uint256(state), uint256(DirectBTCMinter.EventState.Rejected));
        
        // Check no tokens were minted
        assertEq(uniBTCToken.balanceOf(user1), initialBalance);
        
        // Check processIdx was incremented
        assertEq(minter.processIdx(), 1);
    }
    
    function testRejectEventOnlyApprover() public {
        bytes32 txHash = keccak256("test_tx");
        uint256 amount = 1e8;
        
        // Add event
        vm.prank(operator);
        minter.receiveEvent(user1, txHash, amount);
        
        // Try to reject as non-approver
        vm.prank(user1);
        vm.expectRevert();
        minter.rejectEvent(txHash);
    }
    
    function testSetRecipient() public {
        address newRecipient = vm.addr(0x99);
        
        vm.prank(approver);
        vm.expectEmit(true, false, false, true);
        emit RecipientChanged(newRecipient, true);
        
        minter.setRecipient(newRecipient, true);
        
        assertTrue(minter.recipients(newRecipient));
        
        // Test removing recipient
        vm.prank(approver);
        vm.expectEmit(true, false, false, true);
        emit RecipientChanged(newRecipient, false);
        
        minter.setRecipient(newRecipient, false);
        
        assertFalse(minter.recipients(newRecipient));
    }
    
    function testSetRecipientOnlyApprover() public {
        address newRecipient = vm.addr(0x99);
        
        vm.prank(user1);
        vm.expectRevert();
        minter.setRecipient(newRecipient, true);
    }
    
    function testMultipleEventsWorkflow() public {
        // Add multiple events
        vm.startPrank(operator);
        minter.receiveEvent(user1, keccak256("tx1"), 1e8);
        minter.receiveEvent(user2, keccak256("tx2"), 2e8);
        minter.receiveEvent(user1, keccak256("tx3"), 3e8);
        vm.stopPrank();
        
        // Approve first event
        vm.prank(approver);
        minter.approveEvent(keccak256("tx1"));
        assertEq(uniBTCToken.balanceOf(user1), 1e8);
        
        // Reject second event
        vm.prank(approver);
        minter.rejectEvent(keccak256("tx2"));
        assertEq(uniBTCToken.balanceOf(user2), 0);
        
        // Approve third event
        vm.prank(approver);
        minter.approveEvent(keccak256("tx3"));
        assertEq(uniBTCToken.balanceOf(user1), 4e8); // 1e8 + 3e8
    }
    
    function testEventStateEnum() public {
        bytes32 txHash = keccak256("test_tx");
        uint256 amount = 1e8;
        
        // Add event - should be Pending
        vm.prank(operator);
        minter.receiveEvent(user1, txHash, amount);
        
        (, , DirectBTCMinter.EventState state) = minter.receivedEvents(txHash);
        assertEq(uint256(state), 1); // Pending = 1
        
        // Approve event - should be Accepted
        vm.prank(approver);
        minter.approveEvent(txHash);
        
        (, , state) = minter.receivedEvents(txHash);
        assertEq(uint256(state), 2); // Accepted = 2
        
        // Add another event and reject it
        bytes32 txHash2 = keccak256("tx2");
        vm.prank(operator);
        minter.receiveEvent(user1, txHash2, amount);
        
        vm.prank(approver);
        minter.rejectEvent(txHash2);
        
        (, , state) = minter.receivedEvents(txHash2);
        assertEq(uint256(state), 3); // Rejected = 3
    }
    
    function testProcessIdxIncrement() public {
        // Initial processIdx should be 0
        assertEq(minter.processIdx(), 0);
        
        // Add events
        vm.startPrank(operator);
        minter.receiveEvent(user1, keccak256("tx1"), 1e8);
        minter.receiveEvent(user1, keccak256("tx2"), 1e8);
        vm.stopPrank();
        
        // ProcessIdx should still be 0
        assertEq(minter.processIdx(), 0);
        
        // Approve first event
        vm.prank(approver);
        minter.approveEvent(keccak256("tx1"));
        
        // ProcessIdx should be 1
        assertEq(minter.processIdx(), 1);
        
        // Reject second event
        vm.prank(approver);
        minter.rejectEvent(keccak256("tx2"));
        
        // ProcessIdx should be 2
        assertEq(minter.processIdx(), 2);
    }
}