// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ICurve.sol";

contract CurveSwapProxy is Ownable {
    address public immutable router;
    address public immutable pool;
    address public immutable from;
    address public immutable to;
    constructor(address _router, address _pool, address _from, address _to) {
        router = _router;
        pool = _pool;
        from = _from;
        to = _to;
    }
    function swapToken(uint amountIn, uint amountOutMin) external onlyOwner {
        if (IERC20(from).allowance(address(this), router) < amountIn) {
            IERC20(from).approve(router, amountIn);
        }
        uint256 tokenBalanceBefore = IERC20(to).balanceOf(address(this));
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

        ICurveFiRouter(router).exchange(
            route,
            swapParams,
            amountIn,
            amountOutMin,
            pools,
            address(this)
        );
        uint256 tokenBalanceAfter = IERC20(to).balanceOf(address(this));
        uint256 amount = tokenBalanceAfter - tokenBalanceBefore;
        require(amount >= amountOutMin, "USR003");
        emit SwapSuccessAmount(to, amount);
    }

    event SwapSuccessAmount(address token, uint256 amount);
}
