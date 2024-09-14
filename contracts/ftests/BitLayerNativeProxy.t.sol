// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {uniBTC} from "../contracts/uniBTC.sol";
import {Vault} from "../contracts/Vault.sol";
import {BitLayerNativeProxy} from "../contracts/proxies/BitLayerNativeProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract BitLayerNativeProxyTest is Test {
    ERC1967Proxy public vaultProxy;
    ERC1967Proxy public bitLayerProxy;
    Vault public vault;
    BitLayerNativeProxy public bitLayerNative;

    address public uniBTC;
    address public defaultAdmin;
    address public operatorRole;
    address public bitLayerRole;

    function setUp() public {
        defaultAdmin = vm.addr(1);
        operatorRole = vm.addr(2);
        bitLayerRole = vm.addr(3);
        uniBTC = vm.addr(4);

        // deploy vault
        Vault vaultImplementation = new Vault();
        vaultProxy = new ERC1967Proxy(address(vaultImplementation), abi.encodeCall(vaultImplementation.initialize, (defaultAdmin, uniBTC)));
        vault = Vault(payable(vaultProxy));

        // deploy bitLayerProxy
        BitLayerNativeProxy implementation = new BitLayerNativeProxy();
        bitLayerProxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize, (defaultAdmin, address(vaultProxy))));
        bitLayerNative = BitLayerNativeProxy(payable(bitLayerProxy));

        vm.startPrank(defaultAdmin);
        bitLayerNative.grantRole(keccak256("OPERATOR_ROLE"), operatorRole);
        bitLayerNative.grantRole(keccak256("BITLAYER_ROLE"), bitLayerRole);
        vault.grantRole(keccak256("OPERATOR_ROLE"), address(bitLayerNative));
        vm.stopPrank();

        vm.deal(address(vault), 10 ether);
    }

    function test_getBalance() public {
        assertEq(address(vault).balance, 10 ether);
    }

    function test_stakeOK() public {
        vm.startPrank(operatorRole);
        bitLayerNative.stake(1 ether);
        assertEq(address(bitLayerNative).balance, 1 ether);
        assertEq(address(vault).balance, 9 ether);
        bitLayerNative.stake(1 ether);
        assertEq(address(bitLayerNative).balance, 2 ether);
        assertEq(address(vault).balance, 8 ether);
        vm.stopPrank();
    }

    function test_unstake() public {
        vm.startPrank(operatorRole);
        bitLayerNative.stake(5 ether); //nonce 1
        // unstake
        bitLayerNative.unStake(3 ether);//nonce 2
        uint256 queue0 = bitLayerNative.withdrawPendingQueue(2);
        assertEq(queue0, 3 ether);
        vm.stopPrank();
    }

    function test_unstakeOverFlow() public {
        vm.startPrank(operatorRole);
        bitLayerNative.stake(5 ether); //nonce 1
        // unstake
        bitLayerNative.unStake(3 ether);//nonce 2
        vm.expectRevert("amount exceeds staked balance");
        bitLayerNative.unStake(3 ether);//nonce
        vm.stopPrank();
    }

    function test_approveUnbound() public {
        vm.startPrank(operatorRole);
        bitLayerNative.stake(5 ether); //nonce 1
        // unstake
        bitLayerNative.unStake(3 ether);//nonce 2
        vm.stopPrank();

        vm.startPrank(bitLayerRole);
        uint256[] memory reqs = new uint256[](2);
        reqs[0] = 2;
        bitLayerNative.approveUnbound(reqs);
        vm.stopPrank();

        assertEq(address(bitLayerNative).balance, 2 ether);
        assertEq(address(vault).balance, 8 ether);
    }

    function test_flow() public {
        vm.startPrank(operatorRole);
        bitLayerNative.stake(5 ether); //nonce 1
        bitLayerNative.stake(1 ether); //nonce 2
        bitLayerNative.stake(1 ether); //nonce 3
        bitLayerNative.stake(1 ether); //nonce 4
        // unstake
        bitLayerNative.unStake(1 ether);//nonce 5
        bitLayerNative.unStake(1 ether);//nonce 6
        bitLayerNative.unStake(1 ether);//nonce 7
        vm.stopPrank();
        assertEq(address(bitLayerNative).balance, 8 ether);
        assertEq(bitLayerNative.withdrawPendingAmount(), 3 ether);
        assertEq(address(vault).balance, 2 ether);
        assertEq(bitLayerNative.withdrawPendingQueue(5), 1 ether);
        assertEq(bitLayerNative.withdrawPendingQueue(7), 1 ether);

        vm.startPrank(bitLayerRole);
        uint256[] memory reqs = new uint256[](3);
        reqs[0] = 6;
        reqs[1] = 7;
        bitLayerNative.approveUnbound(reqs);
        vm.stopPrank();

        assertEq(address(bitLayerNative).balance, 6 ether);
        assertEq(address(vault).balance, 4 ether);
        assertEq(bitLayerNative.withdrawPendingAmount(), 1 ether);
        assertEq(bitLayerNative.withdrawPendingQueue(6), 0 ether);
        assertEq(bitLayerNative.withdrawPendingQueue(5), 1 ether);

        vm.prank(operatorRole);
        vm.expectRevert("amount exceeds staked balance");
        bitLayerNative.unStake(6 ether);//none
    }
}