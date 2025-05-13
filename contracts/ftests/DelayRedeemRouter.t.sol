// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../contracts/proxies/stateful/redeem/DelayRedeemRouter.sol";

contract DelayRedeemRouterTest is Test {
    DelayRedeemRouter public routerProxy;
    address private constant redeemRouter = address(0xAA732c9c110A84d090a72da230eAe1E779f89246);
    address private constant wbtc = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    address public constant user = address(0x917C50cae9eC15aE554f0d133B20d95680D9D667);
    address public tokenHolder;

    function setUp() public {
        routerProxy = DelayRedeemRouter(payable(redeemRouter));
        tokenHolder = makeAddr("holder");
        deal(routerProxy.uniBTC(), tokenHolder, 2 * 10 ** 8);
    }

    function test_claimToken() public {
        deal(wbtc, user, 0);
        console.log("user's WBTC balance:", ERC20(wbtc).balanceOf(user));
        console.log("router's unibtc balance:",ERC20(routerProxy.uniBTC()).balanceOf(redeemRouter));
        //time travel
        uint256 newTimestamp = block.timestamp + 1 days;
        vm.warp(newTimestamp);
        vm.startPrank(user);
        routerProxy.claimDelayedRedeems();
        vm.stopPrank();
        console.log("user's WBTC balance after claim:", ERC20(wbtc).balanceOf(user));
        console.log("router's unibtc balance after claim:",ERC20(routerProxy.uniBTC()).balanceOf(redeemRouter));
    }

    function test_redeemToken() public {
        vm.startPrank(tokenHolder);
        uint256 uniPrincipal = ERC20(routerProxy.uniBTC()).balanceOf(tokenHolder);
        uint256 redeemAmount = 10 ** 8;
        routerProxy.createDelayedRedeem(wbtc, redeemAmount);
        //time travel
        uint256 newTimestamp = block.timestamp + 8 days;
        vm.warp(newTimestamp);

        bool redeem = routerProxy.canClaimDelayedRedeem(tokenHolder, 0);
        assert(redeem == true);
        routerProxy.claimDelayedRedeems();
        assert(ERC20(wbtc).balanceOf(tokenHolder) == redeemAmount);

        DelayRedeemRouter.DelayedRedeem[] memory redeems = routerProxy.getClaimableUserDelayedRedeems(tokenHolder);
        assert(redeems.length == 0);
        routerProxy.claimDelayedRedeems();
        assert(ERC20(wbtc).balanceOf(tokenHolder) == redeemAmount);

        newTimestamp = block.timestamp + 30 days;
        vm.warp(newTimestamp);
        routerProxy.claimPrincipals();
        uint256 newPrincipals = uniPrincipal - redeemAmount;
        assert(ERC20(routerProxy.uniBTC()).balanceOf(tokenHolder) == newPrincipals);
        vm.stopPrank();
    }

    function test_redeemPrincipal() public {
        vm.startPrank(tokenHolder);
        uint256 uniPrincipal = ERC20(routerProxy.uniBTC()).balanceOf(tokenHolder);
        uint256 redeemAmount = 10 ** 8;
        routerProxy.createDelayedRedeem(wbtc, redeemAmount);
        //time travel
        uint256 newTimestamp = block.timestamp + 30 days;
        vm.warp(newTimestamp);
        routerProxy.claimPrincipals();
        uint256 newPrincipals = uniPrincipal - redeemAmount;
        assert(ERC20(routerProxy.uniBTC()).balanceOf(tokenHolder) == newPrincipals);
        routerProxy.claimPrincipals();
        assert(ERC20(routerProxy.uniBTC()).balanceOf(tokenHolder) == newPrincipals);
        vm.stopPrank();
    }
}
