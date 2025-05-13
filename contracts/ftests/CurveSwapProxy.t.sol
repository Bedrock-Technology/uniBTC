// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

interface ICurveContract {
    function get_dy(
        address[11] calldata _route,
        uint256[5][5] calldata _swap_params,
        uint256 _amount,
        address[5] calldata _pools
    ) external view returns (uint256);

    function exchange(
        address[11] calldata _route,
        uint256[5][5] calldata _swap_params,
        uint256 _amount,
        uint256 _min_dy,
        address[5] calldata _pools
    ) external payable returns (uint256 amountOut);
}

contract CurveSwapProxyTest is Test {
    ICurveContract public contractInstance;
    address private constant CONTRACT_ADDRESS =
        address(0x16C6521Dff6baB339122a0FE25a9116693265353);
    address private constant from =
        address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    address public constant to =
        address(0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf);
    address public constant pool =
        address(0x839d6bDeDFF886404A6d7a788ef241e4e28F4802);
    address public tokenHolder;    

    function setUp() public {
        contractInstance = ICurveContract(CONTRACT_ADDRESS);
        tokenHolder = makeAddr("holder");
        deal(from,tokenHolder, 2*10**8);
    }

    function test_getdy() view public {
        uint256 amount = 1*10**8;
        uint256[5][5] memory swapParams;
        swapParams[0][0] = 0;
        swapParams[0][1] = 1;
        swapParams[0][2] = 1;
        swapParams[0][3] = 10;
        swapParams[0][4] = 2;
        address[11] memory route;
        route[0] = from;
        route[1] = pool;
        route[2] = to;
        address[5] memory pools;
        pools[0] = pool;
        uint256 result = contractInstance.get_dy(
            route,
            swapParams,
            amount,
            pools
        );
        console.log("Current value:", result);
        assert(result > amount);
    }

    function test_exchange() public {
        uint256 amount = 1*10**8;
        uint256 minOut = amount * 99 / 100;
        uint256[5][5] memory swapParams;
        swapParams[0][0] = 1;
        swapParams[0][1] = 0;
        swapParams[0][2] = 1;
        swapParams[0][3] = 10;
        //swapParams[0][4] = 2;
        swapParams[0][4] = 0;
        address[11] memory route;
        route[0] = from;
        route[1] = pool;
        route[2] = to;
        address[5] memory pools;
        pools[0] = pool;

        vm.startPrank(tokenHolder);
        IERC20(from).approve(CONTRACT_ADDRESS, amount);
        uint256 result = contractInstance.exchange(
            route,
            swapParams,
            amount,
            minOut,
            pools
        ); 
        vm.stopPrank();
        console.log("Current value:", result);
        assert(result > minOut);
    }
}
