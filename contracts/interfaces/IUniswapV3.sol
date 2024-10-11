// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Reference: https://etherscan.io/address/0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45
interface IUniswapV3Router02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

//Reference: https://etherscan.io/address/0x9dbe5dFfAEB4Ac2e0ac14F8B4e08b3bc55De5232
interface IUniswapV3Pool {
    function fee() external view returns (uint24);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

