// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contracts/proxies/SwapProxy.sol";
import "../contracts/Vault.sol";

contract SwapProxyTest is Test {
    SwapProxy public swapProxy;
    Vault public vault;
    address public router;
    address public fromToken;
    address public toToken;
    address private constant bedrockVault = address(0x047D41F2544B7F63A8e991aF2068a363d210d6Da);
    //address private constant bedrockVault = address(0x84E5C854A7fF9F49c888d69DECa578D406C26800);//bsc
    address public owner = address(0xC9dA980fFABbE2bbe15d4734FDae5761B86b5Fc3);
    //address public owner = address(0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB);//bsc

    function setUp() public {
        vault = Vault(payable(bedrockVault));
    }

    //forge test --match-path ftests/SwapProxy.t.sol --match-test test_swapUniV3 --fork-url https://eth.llamarpc.com -vvv
    function test_swapUniV3() public {
        fromToken = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        toToken = address(0xC96dE26018A54D51c097160568752c4E3BD6C364);
        router = address(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        address poolOne = address(0x9dbe5dFfAEB4Ac2e0ac14F8B4e08b3bc55De5232);
        address poolTwo = address(0xFB82dd4D657033133eEA6E5B7015042984C5825f);

        deal(fromToken, bedrockVault, 2 * 10 ** 8);
        vm.startPrank(owner);
        swapProxy = new SwapProxy(bedrockVault, fromToken, toToken);
        vm.stopPrank();
        console.log("deploy SwapProxy contract address is:", address(swapProxy));
        console.log("swapProxy swap type is:", swapProxy.getSwapType());

        assert(swapProxy.owner() == owner);
        assert(swapProxy.vault() == bedrockVault);
        assert(swapProxy.fromToken() == fromToken);
        assert(swapProxy.toToken() == toToken);
        bytes32 ERROR_PROTOCOL = keccak256("ERROR_PROTOCOL");
        vm.startPrank(owner);
        vm.expectRevert("USR021");
        swapProxy.addRouter(router, ERROR_PROTOCOL);
        vm.stopPrank();

        vm.startPrank(owner);
        swapProxy.addRouter(router, swapProxy.UNISWAP_V3_PROTOCOL());
        console.log("addRouter success,router is:", swapProxy.getRouter(swapProxy.UNISWAP_V3_PROTOCOL()));
        vm.stopPrank();

        vm.startPrank(owner);
        swapProxy.addPool(poolOne, swapProxy.UNISWAP_V3_PROTOCOL());
        swapProxy.addPool(poolTwo, swapProxy.UNISWAP_V3_PROTOCOL());
        vault.grantRole(vault.OPERATOR_ROLE(), address(swapProxy));
        address[] memory allowTarget = new address[](1);
        allowTarget[0] = router;
        vault.allowTarget(allowTarget);
        vm.stopPrank();

        uint256 swapValue = 1 * 10 ** 8;
        uint256 slippage = 99;

        vm.startPrank(owner);
        swapProxy.swapToken(swapValue, poolOne, slippage, true);
        vm.stopPrank();

        vm.startPrank(owner);
        swapProxy.swapToken(swapValue, poolTwo, slippage, true);
        vm.stopPrank();
    }

    function test_swapUniV2() public {
        fromToken = address(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
        toToken = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        router = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address poolOne = address(0x3f3eE751ab00246cB0BEEC2E904eF51e18AC4d77);
        deal(fromToken, bedrockVault, 2 * 10 ** 8);
        vm.startPrank(owner);
        swapProxy = new SwapProxy(bedrockVault, fromToken, toToken);
        vm.stopPrank();
        console.log("deploy SwapProxy contract address is:", address(swapProxy));
        console.log("swapProxy swap type is:", swapProxy.getSwapType());

        vm.startPrank(owner);
        swapProxy.addRouter(router, swapProxy.UNISWAP_V2_PROTOCOL());
        console.log("addRouter success,router is:", swapProxy.getRouter(swapProxy.UNISWAP_V2_PROTOCOL()));
        vm.stopPrank();

        vm.startPrank(owner);
        swapProxy.addPool(poolOne, swapProxy.UNISWAP_V2_PROTOCOL());
        vault.grantRole(vault.OPERATOR_ROLE(), address(swapProxy));
        address[] memory allowTarget = new address[](2);
        allowTarget[0] = router;
        allowTarget[1] = fromToken;
        vault.allowTarget(allowTarget);
        vm.stopPrank();

        uint256 swapValue = 1 * 10 ** 8;
        uint256 slippage = 5;

        vm.startPrank(owner);
        swapProxy.swapToken(swapValue, poolOne, slippage, false);
        vm.stopPrank();
    }

    function test_swapCurve() public {
        fromToken = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        toToken = address(0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf);
        router = address(0x16C6521Dff6baB339122a0FE25a9116693265353);
        address poolOne = address(0x839d6bDeDFF886404A6d7a788ef241e4e28F4802);
        deal(fromToken, bedrockVault, 2 * 10 ** 8);
        vm.startPrank(owner);
        swapProxy = new SwapProxy(bedrockVault, fromToken, toToken);
        vm.stopPrank();
        console.log("deploy SwapProxy contract address is:", address(swapProxy));
        console.log("swapProxy swap type is:", swapProxy.getSwapType());

        vm.startPrank(owner);
        swapProxy.addRouter(router, swapProxy.CURVE_PROTOCOL());
        console.log("addRouter success,router is:", swapProxy.getRouter(swapProxy.CURVE_PROTOCOL()));
        vm.stopPrank();

        vm.startPrank(owner);
        swapProxy.addPool(poolOne, swapProxy.CURVE_PROTOCOL());
        vault.grantRole(vault.OPERATOR_ROLE(), address(swapProxy));
        address[] memory allowTarget = new address[](2);
        allowTarget[0] = router;
        allowTarget[1] = fromToken;
        vault.allowTarget(allowTarget);
        vm.stopPrank();

        uint256 swapValue = 1 * 10 ** 8;
        uint256 slippage = 99;

        vm.startPrank(owner);
        swapProxy.swapToken(swapValue, poolOne, slippage, true);
        vm.stopPrank();
    }
    /*
    function test_swapDODOV2ProxyV2BSC() public {
        fromToken = address(0xC96dE26018A54D51c097160568752c4E3BD6C364);
        toToken = address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);
        //fromToken = address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);
        //toToken = address(0xC96dE26018A54D51c097160568752c4E3BD6C364);
        router = address(0x8F8Dd7DB1bDA5eD3da8C9daf3bfa471c12d58486);
        address poolOne = address(0xD39DFbfBA9E7eccd813918FfbDa10B783EA3b3C6);

        deal(fromToken, bedrockVault, 2 * 10 ** 8);
        deal(toToken, bedrockVault, 0);
        vm.startPrank(owner);
        swapProxy = new SwapProxy(bedrockVault, fromToken, toToken);
        vm.stopPrank();
        console.log("deploy SwapProxy contract address is:", address(swapProxy));
        console.log("swapProxy swap type is:", swapProxy.getSwapType());

        vm.startPrank(owner);
        swapProxy.addRouter(router, swapProxy.DODO_PROTOCOL());
        console.log("addRouter success,router is:", swapProxy.getRouter(swapProxy.DODO_PROTOCOL()));
        vm.stopPrank();

        vm.startPrank(owner);
        swapProxy.addPool(poolOne, swapProxy.DODO_PROTOCOL());
        vault.grantRole(vault.OPERATOR_ROLE(), address(swapProxy));
        address[] memory allowTarget = new address[](1);
        allowTarget[0] = router;
        vault.allowTarget(allowTarget);
        vm.stopPrank();

        uint256 swapValue = 1 * 10 ** 8;
        uint256 slippage = 90;

        vm.startPrank(owner);
        swapProxy.swapToken(swapValue, poolOne, slippage, true);
        vm.stopPrank();
    }
    */

    function test_swapDODOV2ProxyV2() public {
        //fromToken = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        //toToken = address(0xC96dE26018A54D51c097160568752c4E3BD6C364);
        fromToken = address(0xC96dE26018A54D51c097160568752c4E3BD6C364);
        toToken = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        router = address(0xa356867fDCEa8e71AEaF87805808803806231FdC);
        address poolOne = address(0xD39DFbfBA9E7eccd813918FfbDa10B783EA3b3C6);

        deal(fromToken, bedrockVault, 2 * 10 ** 8);
        vm.startPrank(owner);
        swapProxy = new SwapProxy(bedrockVault, fromToken, toToken);
        vm.stopPrank();
        console.log("deploy SwapProxy contract address is:", address(swapProxy));
        console.log("swapProxy swap type is:", swapProxy.getSwapType());

        vm.startPrank(owner);
        swapProxy.addRouter(router, swapProxy.DODO_PROTOCOL());
        console.log("addRouter success,router is:", swapProxy.getRouter(swapProxy.DODO_PROTOCOL()));
        vm.stopPrank();

        vm.startPrank(owner);
        swapProxy.addPool(poolOne, swapProxy.DODO_PROTOCOL());
        vault.grantRole(vault.OPERATOR_ROLE(), address(swapProxy));
        address[] memory allowTarget = new address[](1);
        allowTarget[0] = router;
        vault.allowTarget(allowTarget);
        vm.stopPrank();

        uint256 swapValue = 1 * 10 ** 4;
        uint256 slippage = 99;

        vm.startPrank(owner);
        swapProxy.swapToken(swapValue, poolOne, slippage, true);
        vm.stopPrank();
    }

    function test_swapBalancerV2Vault() public {
        fromToken = address(0xF1376bceF0f78459C0Ed0ba5ddce976F1ddF51F4);
        toToken = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        router = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        address poolOne = address(0xdD59f89B5B07B7844d72996fC9d83D81acC82196);

        deal(fromToken, bedrockVault, 2 * 10 ** 18);
        vm.startPrank(owner);
        swapProxy = new SwapProxy(bedrockVault, fromToken, toToken);
        vm.stopPrank();
        console.log("deploy SwapProxy contract address is:", address(swapProxy));
        console.log("swapProxy swap type is:", swapProxy.getSwapType());

        vm.startPrank(owner);
        swapProxy.addRouter(router, swapProxy.BALANCER_PROTOCOL());
        console.log("addRouter success,router is:", swapProxy.getRouter(swapProxy.BALANCER_PROTOCOL()));
        vm.stopPrank();

        vm.startPrank(owner);
        swapProxy.addPool(poolOne, swapProxy.BALANCER_PROTOCOL());
        vault.grantRole(vault.OPERATOR_ROLE(), address(swapProxy));
        address[] memory allowTarget = new address[](2);
        allowTarget[0] = router;
        allowTarget[1] = fromToken;
        vault.allowTarget(allowTarget);
        vm.stopPrank();

        uint256 swapValue = 1 * 10 ** 18;
        uint256 slippage = 10;

        vm.startPrank(owner);
        swapProxy.swapToken(swapValue, poolOne, slippage, false);
        vm.stopPrank();
    }
}
