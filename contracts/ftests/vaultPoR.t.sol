// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {uniBTC} from "../contracts/uniBTC.sol";
import {VaultWithoutNative} from "../contracts/VaultWithoutNative.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/data-feeds/interfaces/AggregatorV3Interface.sol";

contract vaultTest is Test {
    ProxyAdmin _proxyAdmin = ProxyAdmin(0x029E4FbDAa31DE075dD74B2238222A08233978f6);
    address public vault = 0x047D41F2544B7F63A8e991aF2068a363d210d6Da;

    function setUp() public {
        VaultWithoutNative _impl = new VaultWithoutNative();

        vm.startPrank(_proxyAdmin.owner());
        _proxyAdmin.upgrade(ITransparentUpgradeableProxy(vault), address(_impl));
        vm.stopPrank();
    }

    function testPoR() public {
        address _admin = address(0xC9dA980fFABbE2bbe15d4734FDae5761B86b5Fc3);
        VaultWithoutNative _v = VaultWithoutNative(payable(vault));

        address _operator = address(0xaaaabbbbccccdddd);

        vm.startPrank(_admin);
        _v.setPoRFeeder(address(0xc590D9fb8eE78a0909dFF341ccf717000b7b7fF2), address(0xE542919E4b281f10b437F947c8Ba224DdfaBc716), 86400);
        _v.grantRole(_v.OPERATOR_ROLE(), _operator);
        vm.stopPrank();

        vm.startPrank(_operator);
        vm.expectRevert(bytes("SYS001"));
        _v.setAdequacyRatio(0);

        vm.expectRevert(bytes("SYS001"));
        _v.setAdequacyRatio(1001);

        _v.setAdequacyRatio(1000);
        _v.setAdequacyRatio(0.99 * 1000);
        vm.stopPrank();

        IERC20 wbtc = IERC20(address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599));
        address _testUser = address(0xF977814e90dA44bFA03b6295A0616a897441aceC);
        vm.startPrank(_testUser);
        wbtc.approve(vault, type(uint256).max);
        _v.mint(address(wbtc), 5 * 1e8);
        vm.stopPrank();
    }
}
