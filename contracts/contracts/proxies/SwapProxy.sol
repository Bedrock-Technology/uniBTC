// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IUniswapV3.sol";
import "../../interfaces/IUniswapV2.sol";
import "../../interfaces/ICurve.sol";
import "../../interfaces/IERC20Symbol.sol";
import "../../interfaces/IDODOV2.sol";
import "../../interfaces/IBalancer.sol";

contract SwapProxy is Ownable {
    ///define slippage range, precision to ten thousandths
    uint256 public constant SLIPPAGE_RANGE = 10000;
    ///default slippage(0.5%)
    uint256 public constant SLIPPAGE_DEFAULT = 50;
    ///max slippage(1%)
    uint256 public constant SLIPPAGE_MAX = 100;
    ///define uniswapV2 protocol
    bytes32 public constant UNISWAP_V2_PROTOCOL =
        keccak256("UNISWAP_V2_PROTOCOL");
    ///define uniswapV3 protocol
    bytes32 public constant UNISWAP_V3_PROTOCOL =
        keccak256("UNISWAP_V3_PROTOCOL");
    ///define curve protocol
    bytes32 public constant CURVE_PROTOCOL = keccak256("CURVE_PROTOCOL");
    ///define DODO protocol
    bytes32 public constant DODO_PROTOCOL = keccak256("DODO_PROTOCOL");
    ///define balancer protocol
    bytes32 public constant BALANCER_PROTOCOL = keccak256("BALANCER_PROTOCOL");
    address public immutable bedrockVault;
    address public immutable fromToken;
    address public immutable toToken;
    ///record uniswapV3, uniswapV2, curve protocol routers
    mapping(bytes32 => address) internal _routers;
    ///record single pool info
    struct PoolInfo {
        bytes32 protocol;
        bool isValid;
        bool existed;
    }
    ///record added pool list
    address[] internal _pools;
    mapping(address => PoolInfo) internal _poolsInfo;

    ///record a pool coin depth info
    struct PoolDepthInfo {
        bytes32 protocol;
        address pool;
        uint256 fromTokenAmount;
        uint256 toTokenAmount;
    }

    receive() external payable {
        revert("value only accepted by the Vault contract");
    }

    constructor(address _vault, address _fromToken, address _toToken) {
        require(_vault != address(0), "SYS001");
        require(_fromToken != address(0), "SYS001");
        require(_toToken != address(0), "SYS001");
        bedrockVault = _vault;
        fromToken = _fromToken;
        toToken = _toToken;
    }

    /**
     * ======================================================================================
     *
     * EXTERNAL FUNCTIONS
     *
     * ======================================================================================
     */
    /**
     * @dev Receive an exact amount of input token for as few output tokens as possible
     * @param amountIn The amount of input token to send.
     * @param pool The pool using for swapping
     * @param slippage The custom slippage for the swap.
     * @param forward The custom slippage direction for the swap.
     */
    function swapToken(
        uint256 amountIn,
        address pool,
        uint256 slippage,
        bool forward
    ) external onlyOwner {
        require(slippage < SLIPPAGE_MAX, "USR011");
        _swap(amountIn, slippage, pool, forward);
    }

    /**
     * @dev Receive an exact amount of input token for as few output tokens as possible
     * @param amountIn The amount of input token to send.
     * @param pool The pool using for swapping
     * @param forward The custom slippage direction for the swap.
     * The default slippage(0.5%) for the swap.
     */
    function swapToken(
        uint256 amountIn,
        address pool,
        bool forward
    ) external onlyOwner {
        _swap(amountIn, SLIPPAGE_DEFAULT, pool, forward);
    }

    /**
     * @dev add an exact router of special protocol
     * @param router the address of router
     * @param protocol only support(uniswapV3,uniswapV2,curve,dodo,balancer)
     */
    function addRouter(address router, bytes32 protocol) external onlyOwner {
        _checkProtocol(protocol);
        require(_routers[protocol] == address(0x0), "USR020");
        _routers[protocol] = router;
    }

    /**
     * @dev add an exact pool of special protocol
     * @param pool the address of pool
     * @param protocol only support(uniswapV3,uniswapV2,curve,dodo,balancer)
     */
    function addPool(address pool, bytes32 protocol) external onlyOwner {
        _checkProtocol(protocol);
        require(!_poolsInfo[pool].existed, "USR020");
        _pools.push(pool);
        _poolsInfo[pool].protocol = protocol;
        _poolsInfo[pool].isValid = true;
        _poolsInfo[pool].existed = true;
    }

    /**
     * @dev set an exact pool valid status of special protocol
     * @param pool the address of pool
     * @param protocol only support(uniswapV3,uniswapV2,curve,dodo,balancer)
     */
    function setPoolValid(
        address pool,
        bytes32 protocol,
        bool status
    ) external onlyOwner {
        _checkProtocol(protocol);
        require(_poolsInfo[pool].existed, "USR022");
        _poolsInfo[pool].isValid = status;
    }

    /**
     * @dev get the coin depth of the pools
     */
    function getPoolsDepth() external view returns (PoolDepthInfo[] memory) {
        PoolDepthInfo[] memory depths = new PoolDepthInfo[](_pools.length);
        uint256 validPoolNum = 0;
        for (uint256 i = 0; i < _pools.length; i++) {
            if (!_poolsInfo[_pools[i]].isValid) {
                continue;
            }
            depths[i].protocol = _poolsInfo[_pools[i]].protocol;
            depths[i].pool = _pools[i];
            depths[i].fromTokenAmount = IERC20(fromToken).balanceOf(_pools[i]);
            depths[i].toTokenAmount = IERC20(toToken).balanceOf(_pools[i]);
            validPoolNum++;
        }
        if (validPoolNum < _pools.length) {
            PoolDepthInfo[] memory validDepths = new PoolDepthInfo[](
                validPoolNum
            );
            for (uint256 i = 0; i < validPoolNum; i++) {
                validDepths[i] = depths[i];
            }
            return validDepths;
        }
        return depths;
    }

    /**
     * @dev swap coin describe
     */
    function getExchangeType() external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    IERC20Symbol(fromToken).symbol(),
                    " -> ",
                    IERC20Symbol(toToken).symbol()
                )
            );
    }

    /**
     * @dev give the address of the protocol router
     */
    function getRouter(bytes32 protocol) external view returns (address) {
        return _routers[protocol];
    }

    /**
     * @dev give the address of the pools
     */
    function getPools() external view returns (address[] memory) {
        return _pools;
    }
    /**
     * ======================================================================================
     *
     * INTERNAL FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * @dev using a pool to swap coin
     */
    function _swap(
        uint256 amountIn,
        uint256 slippage,
        address pool,
        bool forward
    ) internal {
        require(_poolsInfo[pool].isValid, "USR021");
        require(amountIn > 0, "USR014");
        uint256 amountOutMin;
        if (!forward) {
            amountOutMin =
                (amountIn * (SLIPPAGE_RANGE + slippage)) /
                SLIPPAGE_RANGE;
        } else {
            amountOutMin =
                (amountIn * (SLIPPAGE_RANGE - slippage)) /
                SLIPPAGE_RANGE;
        }
        uint256 vaultToTokenBalanceBefore = IERC20(toToken).balanceOf(
            bedrockVault
        );
        if (_poolsInfo[pool].protocol == UNISWAP_V3_PROTOCOL) {
            _swapByUniswapV3Router2(amountIn, amountOutMin, pool);
        } else if (_poolsInfo[pool].protocol == UNISWAP_V2_PROTOCOL) {
            _swapByUniswapV2Router2(amountIn, amountOutMin);
        } else if (_poolsInfo[pool].protocol == CURVE_PROTOCOL) {
            _swapByCurve(amountIn, amountOutMin, pool);
        } else if (_poolsInfo[pool].protocol == DODO_PROTOCOL) {
            _swapByDODOV2Proxy02(amountIn, amountOutMin, pool);
        } else if (_poolsInfo[pool].protocol == BALANCER_PROTOCOL) {
            _swapByBalancerV2Vault(amountIn, amountOutMin, pool);
        }
        uint256 vaultToTokenBalanceAfter = IERC20(toToken).balanceOf(
            bedrockVault
        );
        uint256 amount = vaultToTokenBalanceAfter - vaultToTokenBalanceBefore;
        require(amount >= amountOutMin, "USR003");

        emit SwapSuccessAmount(toToken, amount);
    }
    /**
     * @dev call uniswap v3 router2 to swap fromToken to toToken
     * reference: https://etherscan.io/address/0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45
     * method: exactInputSingle
     * @param amountIn The amount of input token to send.
     * @param amountOutMin The minimum amount of output token that must be received for the transaction not to revert.
     * @param pool The pool using for swapping
     */
    function _swapByUniswapV3Router2(
        uint256 amountIn,
        uint256 amountOutMin,
        address pool
    ) internal {
        // 1. Approve 'amountIn' fromToken to uniswapV3Router02 contract
        _approve(amountIn, _routers[UNISWAP_V3_PROTOCOL]);
        // 2. swap fromToken to toToken using uniswapV3Router02 contract.
        //@ExactInputSingleParams
        //tokenIn: The contract address of the inbound token
        //tokenOut: The contract address of the outbound token
        //fee: The fee tier of the pool, used to determine the correct pool contract in which to execute the swap
        //recipient: the destination address of the outbound token
        //amountOutMinimum: The minimum amount of the outbound token that must be received for the transaction not to revert
        //sqrtPriceLimitX96: We set this to zero - which makes this parameter inactive.
        IUniswapV3Router02.ExactInputSingleParams
            memory params = IUniswapV3Router02.ExactInputSingleParams({
                tokenIn: fromToken,
                tokenOut: toToken,
                fee: IUniswapV3Pool(pool).fee(),
                recipient: bedrockVault,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        bytes memory data = abi.encodeWithSelector(
            IUniswapV3Router02.exactInputSingle.selector,
            params
        );
        IVault(bedrockVault).execute(_routers[UNISWAP_V3_PROTOCOL], data, 0);
        //after spend approve value,check allowance
        _checkAllowance(_routers[UNISWAP_V3_PROTOCOL]);
    }

    /**
     * @dev call uniswap v2 router2 to swap fromToken to toToken
     * reference: https://etherscan.io/address/0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
     * method: swapExactTokensForTokens
     * @param amountIn The amount of input token to send.
     * @param amountOutMin The minimum amount of output token that must be received for the transaction not to revert.
     */
    function _swapByUniswapV2Router2(
        uint256 amountIn,
        uint256 amountOutMin
    ) internal {
        // 1. Approve 'amountIn' fromToken to uniswapV2Router02 contract
        _approve(amountIn, _routers[UNISWAP_V2_PROTOCOL]);
        // 2. swap fromToken to toToken using uniswapV2Router02 contract.
        //@amountIn: The amount of the input token to send.
        //@amountOutMin: The minimum amount of the output token that must be received for the transaction not to revert.
        //@pool: An array of token addresses. path.length must be >= 2.
        //Pools for each consecutive pair of addresses must exist and have liquidity.
        //@to: The address to receive the output token.
        //@deadline: The block timestamp after which the transaction will revert.
        address[] memory pool = new address[](2);
        pool[0] = fromToken;
        pool[1] = toToken;
        bytes memory data = abi.encodeWithSelector(
            IUniswapV2Router02.swapExactTokensForTokens.selector,
            amountIn,
            amountOutMin,
            pool,
            bedrockVault,
            block.timestamp
        );
        IVault(bedrockVault).execute(_routers[UNISWAP_V2_PROTOCOL], data, 0);
        //after spend approve value,check allowance
        _checkAllowance(_routers[UNISWAP_V2_PROTOCOL]);
    }

    /**
     * @dev call curve.fi router to swap fromToken to toToken
     * reference: https://etherscan.io/address/0x99a58482BD75cbab83b27EC03CA68fF489b5788f
     * method: exchange
     * @param amountIn The amount of input token to send.
     * @param amountOutMin The minimum amount of output token that must be received for the transaction not to revert.
     * @param pool The pool using for swapping
     */
    function _swapByCurve(
        uint256 amountIn,
        uint256 amountOutMin,
        address pool
    ) internal {
        // 1. Approve 'amountIn' fromToken to curve router contract
        _approve(amountIn, _routers[CURVE_PROTOCOL]);
        // 2. swap fromToken to toToken using curve router contract.
        // @swapParams: 2D array of swap，Performs up to 5 swaps in a single transaction，here is 1 swap
        // swapParams[n][0] = i, the index of the token to swap from in the n'th pool in `_route`
        // swapParams[n][1] = j, the index of the token to swap to in the n'th pool in `_route`
        // swapParams[n][2] = swap type, the type of swap to do for the n'th pool in `_route`, 1 for a `exchange`
        // swapParams[n][3] in [1, 10]:  stable and stable_ng, reference is not used.
        uint256[5][5] memory swapParams;
        uint256 coinNum = ICurvePool(pool).N_COINS();
        for (uint256 i = 0; i < coinNum; i++) {
            if (ICurvePool(pool).coins(i) == fromToken) {
                swapParams[0][0] = i;
            } else if (ICurvePool(pool).coins(i) == toToken) {
                swapParams[0][1] = i;
            }
        }
        swapParams[0][2] = 1;
        swapParams[0][3] = 10;
        //Array of [initial token, pool, token, pool, token, ...], here is only one pool
        address[11] memory route;
        route[0] = fromToken;
        route[1] = pool;
        route[2] = toToken;
        //Array of pools for swaps via zap contracts. This parameter is only needed for swap_type = 3, here is only one pool
        address[5] memory pools;
        pools[0] = pool;

        bytes memory data = abi.encodeWithSelector(
            ICurveFiRouter.exchange.selector,
            route,
            swapParams,
            amountIn,
            amountOutMin,
            pools,
            bedrockVault
        );
        IVault(bedrockVault).execute(_routers[CURVE_PROTOCOL], data, 0);
        //after spend approve value,check allowance
        _checkAllowance(_routers[CURVE_PROTOCOL]);
    }

    /**
     * @dev call curve router to swap fromToken to toToken
     * reference: https://etherscan.io/address/0xa356867fDCEa8e71AEaF87805808803806231FdC
     * method: dodoSwapV2TokenToToken
     * @param amountIn The amount of input token to send.
     * @param amountOutMin The minimum amount of output token that must be received for the transaction not to revert.
     * @param pool The pool using for swapping
     */
    function _swapByDODOV2Proxy02(
        uint256 amountIn,
        uint256 amountOutMin,
        address pool
    ) internal {
        // 1. Approve 'amountIn' fromToken to dodov2 proxyv2 contract
        address approveProxy = IDODOV2ProxyV2(_routers[DODO_PROTOCOL])
            ._DODO_APPROVE_PROXY_();
        address dodoApprove = IDODOAppProxy(approveProxy)._DODO_APPROVE_();
        _approve(amountIn, dodoApprove);
        // 2. swap fromToken to toToken using dodov2 proxyv2 contract.
        //@fromToken: The contract address of the inbound token
        //@toToken: The contract address of the outbound token
        //@fromTokenAmount: The amount of the inbound token to swap
        //@minReturnAmount: The minimum amount of the outbound token that must be received for the transaction not to revert
        //@dodoPairs: An array of DODO pairs to use for the swap
        //@directions: An array of directions for each pair in `dodoPairs`. sellBaseToken represents 0, sellQuoteToken represents 1
        //@isIncentive: Whether to enable the DODO incentive model
        //@deadLine: The block timestamp after which the transaction will revert
        address[] memory dodoPairs = new address[](1);
        dodoPairs[0] = pool;
        address baseToken = address(IDODOV2Pool(pool)._BASE_TOKEN_());
        uint256 directions;
        if (baseToken == fromToken) {
            directions = 0;
        } else {
            directions = 1;
        }
        bytes memory data = abi.encodeWithSelector(
            IDODOV2ProxyV2.dodoSwapV2TokenToToken.selector,
            fromToken,
            toToken,
            amountIn,
            amountOutMin,
            dodoPairs,
            directions,
            false,
            block.timestamp
        );
        IVault(bedrockVault).execute(_routers[DODO_PROTOCOL], data, 0);
        //after spend approve value,check allowance
        _checkAllowance(dodoApprove);
    }

    /**
     * @dev call balancer v2 vault to swap fromToken to toToken
     */
    function _swapByBalancerV2Vault(
        uint256 amountIn,
        uint256 amountOutMin,
        address pool
    ) internal {
        // 1. Approve 'amountIn' fromToken to balancer v2 vault contract
        _approve(amountIn, _routers[BALANCER_PROTOCOL]);
        // 2. swap fromToken to toToken using balancer v2 vault contract.
        //@SingleSwap: The swap details
        //poolId: The id of the pool to swap with.
        //kind: The type of swap to perform - either "Out Given Exact In" or "In Given Exact Out."
        //assetIn: The address of the token to swap into the pool.
        //assetOut: The address of the token to receive in return.
        //amount: The meaning of amount depends on the value of kind.
        //GIVEN_IN: The amount of tokens being sent
        //GIVEN_OUT: The amount of tokens being received
        //userData: Any additional data which the pool requires to perform the swap
        bytes32 poolId = IBalancerPool(pool).getPoolId();
        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault
            .SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(fromToken),
                assetOut: IAsset(toToken),
                amount: amountIn,
                userData: ""
            });
        //@FundManagement: The funds details
        //sender: The address from which tokens will be taken to perform the swap.
        //fromInternalBalance: Whether the swap should use tokens owned by the sender which are already stored in the Vault.
        //recipient: The address to which tokens will be sent to after the swap.
        //toInternalBalance: Whether the tokens should be sent to the recipient or stored within their internal balance within the Vault.
        IBalancerVault.FundManagement memory funds = IBalancerVault
            .FundManagement({
                sender: bedrockVault,
                fromInternalBalance: false,
                recipient: payable(bedrockVault),
                toInternalBalance: false
            });
        bytes memory data = abi.encodeWithSelector(
            IBalancerVault.swap.selector,
            singleSwap,
            funds,
            amountOutMin,
            block.timestamp
        );
        IVault(bedrockVault).execute(_routers[BALANCER_PROTOCOL], data, 0);
        //after spend approve value,check allowance
        _checkAllowance(_routers[BALANCER_PROTOCOL]);
    }

    /**
     * @dev approve 'amountIn' to spender contract
     * @param amountIn The amount of input token to send.
     * @param spender The address of spender contract
     */
    function _approve(uint256 amountIn, address spender) internal {
        require(
            IERC20(fromToken).balanceOf(bedrockVault) >= amountIn,
            "USR010"
        );
        // 1. Approve 'amountIn' to spender contract
        if (IERC20(fromToken).allowance(bedrockVault, spender) != amountIn) {
            bytes memory data = abi.encodeWithSelector(
                IERC20.approve.selector,
                spender,
                amountIn
            );
            IVault(bedrockVault).execute(fromToken, data, 0);
        }
    }

    /**
     * @dev check allowance of spender contract
     * @param spender The address of spender contract
     */
    function _checkAllowance(address spender) internal view {
        require(
            IERC20(fromToken).allowance(bedrockVault, spender) == 0,
            "USR017"
        );
    }

    /**
     * @dev only support uniswapV3, uniswapV2, curve, dodo, and balancer protocol
     */
    function _checkProtocol(bytes32 protocol) internal pure {
        require(
            protocol == CURVE_PROTOCOL ||
                protocol == UNISWAP_V2_PROTOCOL ||
                protocol == UNISWAP_V3_PROTOCOL ||
                protocol == DODO_PROTOCOL ||
                protocol == BALANCER_PROTOCOL,
            "USR021"
        );
    }

    /**
     * ======================================================================================
     *
     * EVENTS
     *
     * ======================================================================================
     */

    /**
     * @notice event for swap successful event
     */
    event SwapSuccessAmount(address token, uint256 amount);
}
