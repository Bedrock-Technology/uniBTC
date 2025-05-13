// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Contract {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract UniswapV2ProxyTest is Test {
    IUniswapV2Contract public contractInstance;
    address private constant CONTRACT_ADDRESS =
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private constant from =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant to =
        address(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    address public tokenHolder;       

    function setUp() public {
        contractInstance = IUniswapV2Contract(CONTRACT_ADDRESS);
        tokenHolder = makeAddr("holder");
        deal(from,tokenHolder, 2*10**8);
    }

    function test_exchange() public {
        uint256 amount = 2*10**8;
        uint256 minOut = 0;       
        vm.startPrank(tokenHolder);
        IERC20(from).approve(CONTRACT_ADDRESS, amount);
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;
        uint256[] memory result = contractInstance.swapExactTokensForTokens(amount, minOut, path, tokenHolder, block.timestamp);
        vm.stopPrank();
        console.log("Current value:", result[0], result[1]);
        assert(result[0] > result[1]);
    }
}
