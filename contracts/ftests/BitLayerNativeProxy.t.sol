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
    address public bitLayerRole;

    function setUp() public {
        defaultAdmin = vm.addr(1);
        bitLayerRole = vm.addr(2);
        uniBTC = vm.addr(3);

        // deploy vault
        Vault vaultImplementation = new Vault();
        vaultProxy = new ERC1967Proxy(address(vaultImplementation), abi.encodeCall(vaultImplementation.initialize, (defaultAdmin, uniBTC)));
        vault = Vault(payable(vaultProxy));

        // deploy bitLayerProxy
        BitLayerNativeProxy implementation = new BitLayerNativeProxy();
        bitLayerProxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize, (defaultAdmin, address(vaultProxy))));
        bitLayerNative = BitLayerNativeProxy(payable(bitLayerProxy));

        vm.startPrank(defaultAdmin);
        bitLayerNative.grantRole(keccak256("BITLAYER_ROLE"), bitLayerRole);
        vault.grantRole(keccak256("OPERATOR_ROLE"), address(bitLayerNative));
        vm.stopPrank();

        vm.deal(address(vault), 10 ether);
    }

    function test_getBalance() public {
        assertEq(address(vault).balance, 10 ether);
    }

//    function test_nonce() public {
//        uint256 nonce = bitLayerNative.nonce();
//        console.logUint(nonce);
//    }

    function test_stakeOK() public {
        vm.startPrank(defaultAdmin);
        bitLayerNative.stake(1 ether);
        assertEq(address(bitLayerNative).balance, 1 ether);
        assertEq(address(vault).balance, 9 ether);
        bitLayerNative.stake(1 ether);
        assertEq(address(bitLayerNative).balance, 2 ether);
        assertEq(address(vault).balance, 8 ether);
        vm.stopPrank();
    }

    function test_unstake() public {
        vm.startPrank(defaultAdmin);
        bitLayerNative.stake(5 ether); //nonce 22691434096314749681921707768394077297869339642587417088066835679514310029972
        // unstake
        bitLayerNative.unStake(3 ether);//nonce 22691434096314749681921707768394077297869339642587417088066835679514310029973
        uint256 queue0 = bitLayerNative.withdrawPendingQueue(22691434096314749681921707768394077297869339642587417088066835679514310029973);
        assertEq(queue0, 3 ether);
        vm.stopPrank();
    }

    function test_unstakeOverFlow() public {
        vm.startPrank(defaultAdmin);
        bitLayerNative.stake(5 ether); //nonce 22691434096314749681921707768394077297869339642587417088066835679514310029971
        // unstake
        bitLayerNative.unStake(3 ether);//nonce 22691434096314749681921707768394077297869339642587417088066835679514310029972
        vm.expectRevert("amount exceeds staked balance");
        bitLayerNative.unStake(3 ether);//nonce
        vm.stopPrank();
    }

    function test_approveUnbound() public {
        vm.startPrank(defaultAdmin);
        bitLayerNative.stake(5 ether); //nonce 22691434096314749681921707768394077297869339642587417088066835679514310029972
        // unstake
        bitLayerNative.unStake(3 ether);//nonce 22691434096314749681921707768394077297869339642587417088066835679514310029973
        vm.stopPrank();

        vm.startPrank(bitLayerRole);
        uint256[] memory reqs = new uint256[](2);
        reqs[0] = 22691434096314749681921707768394077297869339642587417088066835679514310029973;
        bitLayerNative.approveUnbound(reqs);
        vm.stopPrank();

        assertEq(address(bitLayerNative).balance, 2 ether);
        assertEq(address(vault).balance, 8 ether);
    }

    function test_flow() public {
        vm.startPrank(defaultAdmin);
        bitLayerNative.stake(5 ether); //nonce 22691434096314749681921707768394077297869339642587417088066835679514310029972
        bitLayerNative.stake(1 ether); //nonce 22691434096314749681921707768394077297869339642587417088066835679514310029973
        bitLayerNative.stake(1 ether); //nonce 22691434096314749681921707768394077297869339642587417088066835679514310029974
        bitLayerNative.stake(1 ether); //nonce 22691434096314749681921707768394077297869339642587417088066835679514310029975
        // unstake
        bitLayerNative.unStake(1 ether);//nonce 22691434096314749681921707768394077297869339642587417088066835679514310029976
        bitLayerNative.unStake(1 ether);//nonce 22691434096314749681921707768394077297869339642587417088066835679514310029977
        bitLayerNative.unStake(1 ether);//nonce 22691434096314749681921707768394077297869339642587417088066835679514310029978
        vm.stopPrank();
        assertEq(address(bitLayerNative).balance, 8 ether);
        assertEq(bitLayerNative.withdrawPendingAmount(), 3 ether);
        assertEq(address(vault).balance, 2 ether);
        assertEq(bitLayerNative.withdrawPendingQueue(22691434096314749681921707768394077297869339642587417088066835679514310029976), 1 ether);
        assertEq(bitLayerNative.withdrawPendingQueue(22691434096314749681921707768394077297869339642587417088066835679514310029978), 1 ether);

        vm.startPrank(bitLayerRole);
        uint256[] memory reqs = new uint256[](3);
        reqs[0] = 22691434096314749681921707768394077297869339642587417088066835679514310029977;
        reqs[1] = 22691434096314749681921707768394077297869339642587417088066835679514310029978;
        bitLayerNative.approveUnbound(reqs);
        vm.stopPrank();

        assertEq(address(bitLayerNative).balance, 6 ether);
        assertEq(address(vault).balance, 4 ether);
        assertEq(bitLayerNative.withdrawPendingAmount(), 1 ether);
        assertEq(bitLayerNative.withdrawPendingQueue(22691434096314749681921707768394077297869339642587417088066835679514310029977), 0 ether);
        assertEq(bitLayerNative.withdrawPendingQueue(22691434096314749681921707768394077297869339642587417088066835679514310029976), 1 ether);

        vm.prank(defaultAdmin);
        vm.expectRevert("amount exceeds staked balance");
        bitLayerNative.unStake(6 ether);//none
    }
}