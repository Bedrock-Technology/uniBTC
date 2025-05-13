// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUniswapV2.sol";

contract UniSwapProxy is Ownable {
    address public immutable uniswaprouter;
    constructor(address _router) {
        uniswaprouter = _router;
    }
    function swapToken(uint amountIn,
        uint amountOutMin,
        address[] calldata path) external onlyOwner{
        if (IERC20(path[0]).allowance(address(this), uniswaprouter) < amountIn) {
            IERC20(path[0]).approve(uniswaprouter, amountIn);
        }
        uint256 vaultToTokenBalanceBefore = IERC20(path[1]).balanceOf(
            msg.sender
        );    
        IUniswapV2Router02(uniswaprouter).swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, block.timestamp);
        uint256 vaultToTokenBalanceAfter = IERC20(path[1]).balanceOf(
            msg.sender
        );
        uint256 amount = vaultToTokenBalanceAfter - vaultToTokenBalanceBefore;
        require(amount >= amountOutMin, "USR003");
        emit SwapSuccessAmount(path[1], amount);
    }

    event SwapSuccessAmount(address token, uint256 amount);
}