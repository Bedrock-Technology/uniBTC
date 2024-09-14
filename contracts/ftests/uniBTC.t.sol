// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {uniBTC} from "../contracts/uniBTC.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract uniBTCTest is Test {
    uniBTC public token;
    ERC1967Proxy public proxy;
    address public defaultAdmin;
    address public minter;
    address public user;

    function setUp() public {
        uniBTC implementation = new uniBTC();
        defaultAdmin = vm.addr(1);
        minter = vm.addr(2);
        user = vm.addr(3);
        proxy = new ERC1967Proxy(address(implementation), abi.encodeCall(implementation.initialize, (defaultAdmin, minter)));
        token = uniBTC(address(proxy));
    }

    function test_getDecimal() public {
        assertEq(token.decimals(), 8);
    }

    function test_mint() public {
        vm.prank(minter);
        token.mint(user, 1 * 1e8);
        assertEq(token.balanceOf(user), 1e8);
    }
}