// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/IUniswap.sol";
import "../../interfaces/IVault.sol";

contract WBTCSwapFBTCProxy is Ownable {
    address public immutable BEDROCK_VAULT;
    address public immutable WBTC;
    address public immutable FBTC;
    address public immutable UNISWAP_V3_ROUTER_02;
    address public immutable UNISWAP_WBTC_FBTC_POOL;
    uint24 public immutable UNISWAP_WBTC_FBTC_FEE;
    uint256 public constant SLIPPAGE_RANGE = 10000;
    uint256 public constant SLIPPAGE_DEFAULT = 50;

    receive() external payable {
        revert("value only accepted by the Vault contract");
    }

    constructor(address _vault, address _router, address _pool) {
        BEDROCK_VAULT = _vault;
        UNISWAP_V3_ROUTER_02 = _router;
        UNISWAP_WBTC_FBTC_POOL = _pool;
        WBTC = IUniswapWbtcFbtcPool(_pool).token0();
        FBTC = IUniswapWbtcFbtcPool(_pool).token1();
        UNISWAP_WBTC_FBTC_FEE = IUniswapWbtcFbtcPool(_pool).fee();
    }

    /**
     * ======================================================================================
     *
     * EXTERNAL FUNCTIONS
     *
     * ======================================================================================
     */
    /**
     * @dev Receive an exact amount of fbtc token for as few input wbtc tokens as possible,
     * along the wbtc-fbtc route determined by the path.The first element of path is the input token(wbtc),
     * the last is the output token(fbtc).
     * @param amountIn The amount of wbtc to send.
     * @param slippage The custom slippage for the swap.
     */
    function swapWBTCForFBTC(
        uint256 amountIn,
        uint256 slippage
    ) external onlyOwner {
        require(slippage < SLIPPAGE_RANGE, "USR011");
        _swap(amountIn, slippage);
    }

    /**
     * @dev Receive an exact amount of fbtc token for as few input wbtc tokens as possible,
     * along the wbtc-fbtc route determined by the path.The first element of path is the input token(wbtc),
     * the last is the output token(fbtc).
     * @param amountIn The amount of input tokens to send.
     * @notice default slippage is 0.1%
     */
    function swapWBTCForFBTC(uint256 amountIn) external onlyOwner {
        _swap(amountIn, SLIPPAGE_DEFAULT);
    }

    /**
     * @dev get the wbtc and fbtc balance from uniswap v3 router  wbtc-fbtc pool
     */
    function getUniswapWbtcForFbtcDepth()
        external
        view
        returns (uint256, uint256)
    {
        uint256 wbtcBalance = IERC20(WBTC).balanceOf(UNISWAP_WBTC_FBTC_POOL);
        uint256 fBTCBalance = IERC20(FBTC).balanceOf(UNISWAP_WBTC_FBTC_POOL);
        return (wbtcBalance, fBTCBalance);
    }

    /**
     * ======================================================================================
     *
     * INTERNAL FUNCTIONS
     *
     * ======================================================================================
     */
    /**
     * @dev call uniswap v3 router to swap wbtc to fbtc
     */
    function _swap(uint256 amountIn, uint256 slippage) internal {
        require(IERC20(WBTC).balanceOf(BEDROCK_VAULT) >= amountIn, "USR010");
        uint256 amountOutMin = (amountIn * (SLIPPAGE_RANGE - slippage)) /
            SLIPPAGE_RANGE;
        // 1. Approve '_amount' wBTC to uniswapV3Router02 contract
        bytes memory data;
        if (
            IERC20(WBTC).allowance(BEDROCK_VAULT, UNISWAP_V3_ROUTER_02) <
            amountIn
        ) {
            data = abi.encodeWithSelector(
                IERC20.approve.selector,
                UNISWAP_V3_ROUTER_02,
                amountIn
            );
            IVault(BEDROCK_VAULT).execute(WBTC, data, 0);
        }

        // 2. swap wbtc to fbtc using uniswapV3Router02 contract.
        IUniswapV3Router02.ExactInputSingleParams
            memory params = IUniswapV3Router02.ExactInputSingleParams({
                tokenIn: WBTC,
                tokenOut: FBTC,
                fee: UNISWAP_WBTC_FBTC_FEE,
                recipient: BEDROCK_VAULT,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        data = abi.encodeWithSelector(
            IUniswapV3Router02.exactInputSingle.selector,
            params
        );

        uint256 vaultFbtcBalanceBefore = IERC20(FBTC).balanceOf(BEDROCK_VAULT);
        IVault(BEDROCK_VAULT).execute(UNISWAP_V3_ROUTER_02, data, 0);
        uint256 vaultFbtcBalanceAfter = IERC20(FBTC).balanceOf(BEDROCK_VAULT);
        uint256 amount = vaultFbtcBalanceAfter - vaultFbtcBalanceBefore;
        require(amount >= amountOutMin, "USR003");
        emit SwapWBTCForFBTCAmount(amount);
    }

    /**
     * ======================================================================================
     *
     * EVENTS
     *
     * ======================================================================================
     */

    /**
     * @notice event for swapWBTCForFBTC
     */
    event SwapWBTCForFBTCAmount(uint256 amount);
}
