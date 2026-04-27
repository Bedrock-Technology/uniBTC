// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {uniBTC} from "../mock/uniBTC.sol";
import {cuniBTC} from "../src/cuniBTC.sol";
import {Vault} from "../src/Vault.sol";
import {DelayRedeemRouter} from "../src/DelayRedeemRouter.sol";
import {Airdrop} from "../src/Airdrop.sol";
import {cuniBTC as NewCuniBTC} from "../mock/cuniBTC.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FactoryTest is Test {
    Factory public factory;
    uniBTC public unibtc;
    ProxyAdmin public proxyAdmin;
    address public Owner;
    address public deployer;

    function setUp() public {
        factory = Factory(0x677F4D7Fe9d78223041E2B0f78F5Ac7ae212b3D5);
        unibtc = uniBTC(0x611160Ae2DA00A2735e3400AC4f401918A61800a);
        proxyAdmin = ProxyAdmin(0xB36F69446C756831cCE73bb35bb2D6f75007212c);
        Owner = 0xac07f2721EcD955c4370e7388922fA547E922A4f;
        deployer = 0x8cb37518330014E027396E3ED59A231FBe3B011A;
        vm.startPrank(deployer);
        Factory(factory).transferOwnership(Owner);
        vm.stopPrank();
    }

    //forge test test/Factoryfork.t.sol --match-test testRole --rpc-url $RPC_ETH_HOODI
    function testRole() public view {
        (,, address vault, address _cuniBTC, address delayRedeemRouter, address airdrop) = factory.strategies("cuniBTC");
        assertTrue(Vault(payable(vault)).hasRole(Vault(payable(vault)).DEFAULT_ADMIN_ROLE(), Owner));
        assertFalse(Vault(payable(vault)).hasRole(Vault(payable(vault)).DEFAULT_ADMIN_ROLE(), address(factory)));

        assertTrue(cuniBTC(_cuniBTC).hasRole(cuniBTC(_cuniBTC).DEFAULT_ADMIN_ROLE(), Owner));
        assertFalse(cuniBTC(_cuniBTC).hasRole(cuniBTC(_cuniBTC).DEFAULT_ADMIN_ROLE(), address(factory)));

        assertTrue(
            DelayRedeemRouter(payable(delayRedeemRouter))
                .hasRole(DelayRedeemRouter(payable(delayRedeemRouter)).DEFAULT_ADMIN_ROLE(), Owner)
        );
        assertFalse(
            DelayRedeemRouter(payable(delayRedeemRouter))
                .hasRole(DelayRedeemRouter(payable(delayRedeemRouter)).DEFAULT_ADMIN_ROLE(), address(factory))
        );

        assertTrue(Airdrop(payable(airdrop)).hasRole(Airdrop(payable(airdrop)).DEFAULT_ADMIN_ROLE(), Owner));
        assertFalse(Airdrop(payable(airdrop)).hasRole(Airdrop(payable(airdrop)).DEFAULT_ADMIN_ROLE(), address(factory)));
    }

    //forge test test/Factoryfork.t.sol --match-test testCreateStrategyWithSameName --rpc-url $RPC_ETH_HOODI
    function testCreateStrategyWithSameName() public {
        vm.prank(Owner);
        vm.expectRevert("Strategy already exists");
        factory.createStrategy("cuniBTC", "cuniBTC", address(this), address(unibtc));
    }

    //forge test test/Factoryfork.t.sol --match-test testE2E --rpc-url $RPC_ETH_HOODI
    function testE2E() public {
        // Get strategy info
        (
            string memory name,
            string memory symbol,
            address vault,
            address _cuniBTC,
            address delayRedeemRouter,
            address airdrop
        ) = factory.strategies("cuniBTC");
        Factory.Strategy memory strategy = Factory.Strategy(name, symbol, vault, _cuniBTC, delayRedeemRouter, airdrop);
        vm.prank(Owner);
        uniBTC(unibtc).mint(address(this), 50 * 1e8);
        // swap 50 uniBTC to cuniBTC via vault
        IERC20(address(unibtc)).approve(strategy.vault, 50 * 1e8);
        Vault(payable(strategy.vault)).mint(address(unibtc), 50 * 1e8);
        assertEq(cuniBTC(strategy.cuniBTC).balanceOf(address(this)), 50 * 1e8);
        vm.warp(block.timestamp + 86400);
        // redeem cuniBTC back to uniBTC
        IERC20(address(strategy.cuniBTC)).approve(strategy.delayRedeemRouter, 50 * 1e8);
        DelayRedeemRouter(payable(strategy.delayRedeemRouter)).createDelayedRedeem(address(unibtc), 50 * 1e8);

        //claim
        vm.warp(block.timestamp + 7 * 86400);
        DelayRedeemRouter(payable(strategy.delayRedeemRouter)).claimDelayedRedeems();
        assertEq(unibtc.balanceOf(address(this)), 49 * 1e8);
        assertEq(IERC20(strategy.cuniBTC).balanceOf(address(this)), 0);
    }

    //forge test test/Factoryfork.t.sol --match-test testupgradeBeacon --rpc-url $RPC_ETH_HOODI
    function testupgradeBeacon() public {
        //create another one
        vm.startPrank(Owner);
        factory.createStrategy("cuniBTC", "cuniBTC-2", Owner, address(unibtc));
        address beforeUpgradeAdr = address(factory.cuniBTCImpl());
        NewCuniBTC newcuniBTC = new NewCuniBTC();
        factory.upgradeBeacon(address(factory.cuniBTCBeacon()), address(newcuniBTC));
        address afterUpgradeAdr = address(factory.cuniBTCImpl());
        assertNotEq(beforeUpgradeAdr, afterUpgradeAdr);
        (,,, address _cuniBTC,,) = factory.strategies("cuniBTC");
        (,,, address _cuniBTC2,,) = factory.strategies("cuniBTC-2");
        NewCuniBTC(payable(_cuniBTC)).setVersion(2);
        NewCuniBTC(payable(_cuniBTC2)).setVersion(2);
        assertEq(NewCuniBTC(payable(_cuniBTC)).version(), 2);
        assertEq(NewCuniBTC(payable(_cuniBTC2)).version(), 2);
        factory.createStrategy("cuniBTC", "cuniBTC-3", Owner, address(unibtc));
        (,,, address _cuniBTC3,,) = factory.strategies("cuniBTC-3");
        NewCuniBTC(payable(_cuniBTC3)).setVersion(2);
        vm.stopPrank();
        assertEq(NewCuniBTC(payable(_cuniBTC3)).version(), 2);
    }
}
