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
    Account public Owner = makeAccount("owner");

    function setUp() public {
        uniBTC unibtcImp = new uniBTC();
        ProxyAdmin _proxyAdmin = new ProxyAdmin();
        proxyAdmin = _proxyAdmin;
        proxyAdmin.transferOwnership(Owner.addr);

        TransparentUpgradeableProxy uniBTCProxy = new TransparentUpgradeableProxy(
            address(unibtcImp),
            address(proxyAdmin),
            abi.encodeWithSelector(uniBTC.initialize.selector, Owner.addr, Owner.addr, new address[](0))
        );
        unibtc = uniBTC(address(uniBTCProxy));

        cuniBTC cuniBTCimpl = new cuniBTC();
        Vault vaultimpl = new Vault();
        Airdrop airdropimpl = new Airdrop();
        DelayRedeemRouter delayRedeemRouterImpl = new DelayRedeemRouter();
        Factory factoryImpl = new Factory();

        TransparentUpgradeableProxy factoryProxy = new TransparentUpgradeableProxy(
            address(factoryImpl),
            address(proxyAdmin),
            abi.encodeWithSelector(
                Factory.initialize.selector,
                address(cuniBTCimpl),
                address(vaultimpl),
                address(airdropimpl),
                address(delayRedeemRouterImpl)
            )
        );
        factory = Factory(address(factoryProxy));

        factory.createStrategy("cuniBTC", "cuniBTC", Owner.addr, address(unibtc));
    }

    //forge test test/Factory.t.sol --match-test testCreateStrategy
    function testCreateStrategy() public view {
        (
            string memory name,
            string memory symbol,
            address vault,
            address _cuniBTC,
            address delayRedeemRouter,
            address airdrop
        ) = factory.strategies("cuniBTC");
        assertEq(name, "cuniBTC");
        assertEq(symbol, "cuniBTC");
        assertTrue(vault != address(0));
        assertTrue(_cuniBTC != address(0));
        assertTrue(delayRedeemRouter != address(0));
        assertTrue(airdrop != address(0));
    }

    //forge test test/Factory.t.sol --match-test testRole
    function testRole() public view {
        (,, address vault, address _cuniBTC, address delayRedeemRouter, address airdrop) = factory.strategies("cuniBTC");
        assertTrue(Vault(payable(vault)).hasRole(Vault(payable(vault)).DEFAULT_ADMIN_ROLE(), Owner.addr));
        assertFalse(Vault(payable(vault)).hasRole(Vault(payable(vault)).DEFAULT_ADMIN_ROLE(), address(factory)));

        assertTrue(cuniBTC(_cuniBTC).hasRole(cuniBTC(_cuniBTC).DEFAULT_ADMIN_ROLE(), Owner.addr));
        assertFalse(cuniBTC(_cuniBTC).hasRole(cuniBTC(_cuniBTC).DEFAULT_ADMIN_ROLE(), address(factory)));

        assertTrue(
            DelayRedeemRouter(payable(delayRedeemRouter))
                .hasRole(DelayRedeemRouter(payable(delayRedeemRouter)).DEFAULT_ADMIN_ROLE(), Owner.addr)
        );
        assertFalse(
            DelayRedeemRouter(payable(delayRedeemRouter))
                .hasRole(DelayRedeemRouter(payable(delayRedeemRouter)).DEFAULT_ADMIN_ROLE(), address(factory))
        );

        assertTrue(Airdrop(payable(airdrop)).hasRole(Airdrop(payable(airdrop)).DEFAULT_ADMIN_ROLE(), Owner.addr));
        assertFalse(Airdrop(payable(airdrop)).hasRole(Airdrop(payable(airdrop)).DEFAULT_ADMIN_ROLE(), address(factory)));
    }

    //forge test test/Factory.t.sol --match-test testCreateStrategyWithSameName
    function testCreateStrategyWithSameName() public {
        vm.expectRevert("Strategy already exists");
        factory.createStrategy("cuniBTC", "cuniBTC", address(this), address(unibtc));
    }

    //forge test test/Factory.t.sol --match-test testE2E
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
        vm.prank(Owner.addr);
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

    //forge test test/Factory.t.sol --match-test testupgradeBeacon
    function testupgradeBeacon() public {
        //create another one
        factory.createStrategy("cuniBTC", "cuniBTC-2", Owner.addr, address(unibtc));
        address beforeUpgradeAdr = address(factory.cuniBTCImpl());
        NewCuniBTC newcuniBTC = new NewCuniBTC();
        factory.upgradeBeacon(address(factory.cuniBTCBeacon()), address(newcuniBTC));
        address afterUpgradeAdr = address(factory.cuniBTCImpl());
        assertNotEq(beforeUpgradeAdr, afterUpgradeAdr);
        (,,, address _cuniBTC,,) = factory.strategies("cuniBTC");
        (,,, address _cuniBTC2,,) = factory.strategies("cuniBTC-2");
        vm.prank(Owner.addr);
        NewCuniBTC(payable(_cuniBTC)).setVersion(2);
        vm.prank(Owner.addr);
        NewCuniBTC(payable(_cuniBTC2)).setVersion(2);
        assertEq(NewCuniBTC(payable(_cuniBTC)).version(), 2);
        assertEq(NewCuniBTC(payable(_cuniBTC2)).version(), 2);
        factory.createStrategy("cuniBTC", "cuniBTC-3", Owner.addr, address(unibtc));
        (,,, address _cuniBTC3,,) = factory.strategies("cuniBTC-3");
        vm.prank(Owner.addr);
        NewCuniBTC(payable(_cuniBTC3)).setVersion(2);
        assertEq(NewCuniBTC(payable(_cuniBTC3)).version(), 2);
    }
}
