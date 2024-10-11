// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Reference: https://etherscan.io/address/0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
