// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {uniBTC} from "../contracts/uniBTC.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

// forge test ftests/uniBTC.t.sol -f $RPC_ETH

contract uniBTCTest is Test {
    address public defaultAdmin;
    address public proxyAdminAddress;
    //
    address public forbiddenAddress1;
    address public forbiddenAddress2;
    address public forbidAddress1;
    address public forbidAddress2;
    //
    address public freezeRole;
    TransparentUpgradeableProxy public uniBTCProxy;
    uniBTC public uniBTCIns;

    function setUp() public {
        address proxyAdminOwner = 0xC9dA980fFABbE2bbe15d4734FDae5761B86b5Fc3;
        address vaultMinter = 0x047D41F2544B7F63A8e991aF2068a363d210d6Da;
        proxyAdminAddress = 0x029E4FbDAa31DE075dD74B2238222A08233978f6;
        defaultAdmin = 0xC9dA980fFABbE2bbe15d4734FDae5761B86b5Fc3;
        forbiddenAddress1 = 0x5f2f99f21181D8668EC6E2e761704d9C383f989A;
        forbiddenAddress2 = 0x0290445D5F6F78452D4d70B49C267bD856fDa636;
        forbidAddress1 = vm.addr(0x21);
        forbidAddress2 = vm.addr(0x22);
        freezeRole = vm.addr(0x10);
        vm.startPrank(vm.addr(0x1));
        //deployNew
        uniBTC newUniBTC = new uniBTC();
        vm.stopPrank();
        //upgrade
        uniBTCProxy = TransparentUpgradeableProxy(payable(0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568));
        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        // address[] memory _forbidden = new address[](0);
        uniBTCIns = uniBTC(payable(uniBTCProxy));
        vm.startPrank(proxyAdminOwner);
        // proxyAdmin.upgradeAndCall(
        //     ITransparentUpgradeableProxy(0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568),
        //     address(newUniBTC),
        //     abi.encodeCall(newUniBTC.initialize, (defaultAdmin, defaultAdmin, _forbidden))
        // );
        proxyAdmin.upgrade(ITransparentUpgradeableProxy(0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568), address(newUniBTC));
        uniBTCIns.grantRole(uniBTCIns.FREEZER_ROLE(), freezeRole);
        vm.stopPrank();
        vm.startPrank(vaultMinter);
        uniBTCIns.mint(forbidAddress1, 1000000000);
        uniBTCIns.mint(forbidAddress2, 1000000000);
        vm.stopPrank();
    }

    function test_Inforbidden() public view {
        bool isIn1 = uniBTCIns.frozenUsers(forbiddenAddress1);
        assertEq(isIn1, true);
        bool isIn2 = uniBTCIns.frozenUsers(forbiddenAddress2);
        assertEq(isIn2, true);
    }

    function test_frozenUsers() public {
        vm.startPrank(freezeRole);
        address[] memory users = new address[](2);
        users[0] = forbidAddress1;
        users[1] = forbidAddress2;
        uniBTCIns.freezeUsers(users);
        vm.stopPrank();
        bool isIn1 = uniBTCIns.frozenUsers(forbidAddress1);
        assertEq(isIn1, true);
        bool isIn2 = uniBTCIns.frozenUsers(forbidAddress2);
        assertEq(isIn2, true);
        vm.startPrank(forbidAddress1);
        address[] memory recipients = new address[](1);
        recipients[0] = forbidAddress2;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100000000;
        vm.expectRevert();
        uniBTCIns.batchTransfer(recipients, amounts);
        vm.stopPrank();
        //unfrozenUsers
        vm.startPrank(freezeRole);
        uniBTCIns.unfreezeUsers(users);
        bool isIn3 = uniBTCIns.frozenUsers(forbidAddress1);
        assertEq(isIn3, false);
        bool isIn4 = uniBTCIns.frozenUsers(forbidAddress2);
        assertEq(isIn4, false);
        vm.stopPrank();
        vm.startPrank(forbidAddress1);
        uniBTCIns.batchTransfer(recipients, amounts);
        vm.stopPrank();
        uint256 balance = uniBTCIns.balanceOf(forbidAddress2);
        vm.assertEq(balance, 1100000000);
    }
}
