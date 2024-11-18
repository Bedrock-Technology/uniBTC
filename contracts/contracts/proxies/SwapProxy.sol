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
    /// @notice Defines the precision range for slippage, set to ten-thousandths.
    uint256 public constant SLIPPAGE_RANGE = 10000;

    /// @notice Default slippage set at 0.5%.
    uint256 public constant DEFAULT_SLIPPAGE = 50;

    /// @notice Maximum allowed slippage set at 1%.
    uint256 public constant MAX_SLIPPAGE = 100;

    /// @notice Identifier for the Uniswap V2 protocol, used for protocol routing.
    bytes32 public constant UNISWAP_V2_PROTOCOL = keccak256("UNISWAP_V2_PROTOCOL");

    /// @notice Identifier for the Uniswap V3 protocol, used for protocol routing.
    bytes32 public constant UNISWAP_V3_PROTOCOL = keccak256("UNISWAP_V3_PROTOCOL");

    /// @notice Identifier for the Curve protocol, used for protocol routing.
    bytes32 public constant CURVE_PROTOCOL = keccak256("CURVE_PROTOCOL");

    /// @notice Identifier for the DODO protocol, used for protocol routing.
    bytes32 public constant DODO_PROTOCOL = keccak256("DODO_PROTOCOL");

    /// @notice Identifier for the Balancer protocol, used for protocol routing.
    bytes32 public constant BALANCER_PROTOCOL = keccak256("BALANCER_PROTOCOL");

    /// @notice Address of the Bedrock Vault contract, which manages token storage.
    address public immutable vault;

    /// @notice Address of the token being swapped from.
    address public immutable fromToken;

    /// @notice Address of the token being swapped to.
    address public immutable toToken;

    /// @notice Mapping of protocol identifiers to their router addresses.
    mapping(bytes32 => address) internal _routers;

    /// @notice Structure to store individual pool information.
    /// @param protocol The protocol identifier for the pool, e.g., UNISWAP_V2_PROTOCOL.
    /// @param isValid Indicates if the pool is valid for use in transactions.
    /// @param existed Tracks if the pool has been initialized.
    struct PoolInfo {
        bytes32 protocol;
        bool isValid;
        bool existed;
    }

    /// @notice Stores a list of addresses for added pools.
    address[] internal _pools;

    /// @notice Mapping of pool addresses to their respective PoolInfo structures.
    mapping(address => PoolInfo) internal _poolInfos;

    /// @notice Structure to record depth information of a pool.
    /// @param protocol The protocol identifier for the pool, e.g., UNISWAP_V2_PROTOCOL.
    /// @param pool The address of the liquidity pool.
    /// @param fromTokenAmount Depth in the pool for the `fromToken`.
    /// @param toTokenAmount Depth in the pool for the `toToken`.
    struct PoolDepthInfo {
        bytes32 protocol;
        address pool;
        uint256 fromTokenAmount;
        uint256 toTokenAmount;
    }

    /// @dev Fallback function that reverts if value is sent to this contract.
    ///      Only the Bedrock Vault contract can accept native token.
    receive() external payable {
        revert("value only accepted by the Vault contract");
    }

    /**
     * ======================================================================================
     *
     * CONSTRUCTOR
     *
     * ======================================================================================
     */

    /**
     * @dev Initializes the contract with the specified vault and token addresses.
     * @param _vault Address of the bedrock vault, which serves as the source of funds.
     * @param _fromToken Address of the token to be swapped from (input token).
     * @param _toToken Address of the token to be swapped to (output token).
     */
    constructor(address _vault, address _fromToken, address _toToken) {
        require(_vault != address(0), "SYS001");
        require(_fromToken != address(0), "SYS001");
        require(_toToken != address(0), "SYS001");
        vault = _vault;
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
     * @dev Swaps an exact amount of input tokens to obtain as few output tokens as possible,
     *      applying a slippage tolerance in the specified direction.
     * @param amountIn The amount of input tokens to be swapped.
     * @param pool The address of the liquidity pool used for the swap.
     * @param slippage Custom slippage tolerance for this swap, defined as a percentage of `SLIPPAGE_RANGE`.
     * @param forward If false, applies positive slippage tolerance, allowing higher output variance;
     *                if true, applies negative slippage tolerance, restricting output variance.
     *
     */
    function swapToken(uint256 amountIn, address pool, uint256 slippage, bool forward) external onlyOwner {
        require(slippage < MAX_SLIPPAGE, "USR011");
        _swap(amountIn, slippage, pool, forward);
    }

    /**
     * @dev Swaps an exact amount of input tokens to obtain as few output tokens as possible,
     *      applying a slippage tolerance in the specified direction.
     * @param amountIn The amount of input tokens to be swapped.
     * @param pool The address of the liquidity pool used for the swap.
     * @param forward If false, applies positive slippage tolerance, allowing higher output variance;
     *                if true, applies negative slippage tolerance, restricting output variance.
     *
     */
    function swapToken(uint256 amountIn, address pool, bool forward) external onlyOwner {
        _swap(amountIn, DEFAULT_SLIPPAGE, pool, forward);
    }

    /**
     * @dev Adds a specific router address for a supported protocol.
     *      This function allows the owner to register a router for a given protocol.
     *      Only the following protocols are supported: Uniswap V2, Uniswap V3, Curve, DODO, and Balancer.
     *
     * @param router The address of the router to be added.
     * @param protocol The protocol associated with the router (e.g., Uniswap V2, Uniswap V3, Curve, DODO, Balancer).
     */
    function addRouter(address router, bytes32 protocol) external onlyOwner {
        _checkProtocol(protocol);
        require(_routers[protocol] == address(0x0), "USR020");
        _routers[protocol] = router;
    }

    /**
     * @dev Adds a new pool to the contract and associates it with a specific protocol.
     *      The pool is registered and marked as valid, allowing it to be used for future operations.
     *      Only the contract owner can call this function.
     *
     * @param pool The address of the pool to be added.
     * @param protocol The protocol associated with the pool (e.g., Uniswap V2, Uniswap V3, Curve, DODO, Balancer).
     */
    function addPool(address pool, bytes32 protocol) external onlyOwner {
        _checkProtocol(protocol);
        require(!_poolInfos[pool].existed, "USR020");
        _pools.push(pool);
        _poolInfos[pool].protocol = protocol;
        _poolInfos[pool].isValid = true;
        _poolInfos[pool].existed = true;
    }

    /**
     * @dev Sets the validity status of a pool, allowing the contract owner to enable or disable the pool.
     *      The function can only be called by the owner of the contract.
     *
     * @param pool The address of the pool whose validity status needs to be updated.
     * @param protocol The protocol associated with the pool (e.g., Uniswap V2, Uniswap V3, Curve, DODO, Balancer).
     * @param status The validity status to set for the pool.
     *               If true, the pool is marked as valid; if false, it is marked as invalid.
     */
    function setPoolValid(address pool, bytes32 protocol, bool status) external onlyOwner {
        _checkProtocol(protocol);
        require(_poolInfos[pool].existed, "USR022");
        _poolInfos[pool].isValid = status;
    }

    /**
     * @dev Retrieves the pool depth information for all valid pools.
     *      The depth includes the amount of `fromToken` and `toToken` for each pool.
     *      Only pools that are marked as valid will be included in the result.
     *
     * @return An array of `PoolDepthInfo` containing the protocol, pool address,
     *         and token balances (fromToken and toToken) for each valid pool.
     */
    function getPoolsDepth() external view returns (PoolDepthInfo[] memory) {
        PoolDepthInfo[] memory depths = new PoolDepthInfo[](_pools.length);
        uint256 validPoolNum = 0;

        //--------------------------------------------------------------------------------
        // 1. Iterate through all pools and retrieve depth information,
        //    excluding invalid pools.
        //--------------------------------------------------------------------------------
        for (uint256 i = 0; i < _pools.length; i++) {
            if (!_poolInfos[_pools[i]].isValid) {
                continue;
            }
            depths[i].protocol = _poolInfos[_pools[i]].protocol;
            depths[i].pool = _pools[i];
            depths[i].fromTokenAmount = IERC20(fromToken).balanceOf(_pools[i]);
            depths[i].toTokenAmount = IERC20(toToken).balanceOf(_pools[i]);
            validPoolNum++;
        }

        //--------------------------------------------------------------------------------
        // 2. If there are invalid pools, create a new array with only valid pools.
        //--------------------------------------------------------------------------------
        if (validPoolNum < _pools.length) {
            PoolDepthInfo[] memory validDepths = new PoolDepthInfo[](validPoolNum);
            for (uint256 i = 0; i < validPoolNum; i++) {
                validDepths[i] = depths[i];
            }
            return validDepths;
        }
        return depths;
    }

    /**
     * @dev Returns a human-readable description of the token exchange type.
     * This describes the conversion from the `fromToken` to the `toToken`,
     * showing their respective symbols (e.g., "ETH -> USDT").
     * @return A string representing the exchange type (e.g., "ETH -> USDT").
     */
    function getSwapType() external view returns (string memory) {
        return string(abi.encodePacked(IERC20Symbol(fromToken).symbol(), " -> ", IERC20Symbol(toToken).symbol()));
    }

    /**
     * @dev Returns the address of the router associated with the given protocol.
     * @param protocol The protocol identifier (e.g., UniswapV2, UniswapV3, etc.).
     * @return The address of the router for the specified protocol.
     */
    function getRouter(bytes32 protocol) external view returns (address) {
        return _routers[protocol];
    }

    /**
     * @dev Returns the list of addresses for all registered pools.
     * @return An array of pool addresses.
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
     * @notice Internal function used by both overloaded `swapToken` functions to perform the token swap.
     * @dev Executes a token swap using a specified pool.
     * @param amountIn The amount of input tokens to swap.
     * @param slippage The allowable slippage for the swap.
     * @param pool The address of the pool used for the swap.
     * @param forward If false, applies positive slippage tolerance, allowing higher output variance;
     *                if true, applies negative slippage tolerance, restricting output variance.
     */
    function _swap(uint256 amountIn, uint256 slippage, address pool, bool forward) internal {
        require(_poolInfos[pool].isValid, "USR021");
        require(amountIn > 0, "USR014");
        uint256 amountOutMin;

        //--------------------------------------------------------------------------------
        // 1. Calculate the minimum amount of `toToken` that must be received for the swap.
        //--------------------------------------------------------------------------------
        if (!forward) {
            amountOutMin = (amountIn * (SLIPPAGE_RANGE + slippage)) / SLIPPAGE_RANGE;
        } else {
            amountOutMin = (amountIn * (SLIPPAGE_RANGE - slippage)) / SLIPPAGE_RANGE;
        }

        uint256 vaultToTokenBalanceBefore = IERC20(toToken).balanceOf(vault);

        //--------------------------------------------------------------------------------
        // 2. Execute the swap based on the protocol associated with the pool.
        //--------------------------------------------------------------------------------
        if (_poolInfos[pool].protocol == UNISWAP_V3_PROTOCOL) {
            _swapByUniswapV3Router2(amountIn, amountOutMin, pool);
        } else if (_poolInfos[pool].protocol == UNISWAP_V2_PROTOCOL) {
            _swapByUniswapV2Router2(amountIn, amountOutMin);
        } else if (_poolInfos[pool].protocol == CURVE_PROTOCOL) {
            _swapByCurve(amountIn, amountOutMin, pool);
        } else if (_poolInfos[pool].protocol == DODO_PROTOCOL) {
            _swapByDODOV2Proxy02(amountIn, amountOutMin, pool);
        } else if (_poolInfos[pool].protocol == BALANCER_PROTOCOL) {
            _swapByBalancerV2Vault(amountIn, amountOutMin, pool);
        }

        //--------------------------------------------------------------------------------
        // 3. Verify the swap was successful by checking the balance of the `toToken`.
        //--------------------------------------------------------------------------------
        uint256 vaultToTokenBalanceAfter = IERC20(toToken).balanceOf(vault);
        uint256 amount = vaultToTokenBalanceAfter - vaultToTokenBalanceBefore;
        require(amount >= amountOutMin, "USR003");

        emit SwapSuccessful(toToken, amount);
    }

    /**
     * @dev Executes a token swap from `fromToken` to `toToken` using Uniswap V3 router.
     *      The swap is executed using the `exactInputSingle` method of the Uniswap V3 router.
     *      Reference: https://etherscan.io/address/0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45
     * @param amountIn The amount of `fromToken` to send.
     * @param amountOutMin The minimum amount of `toToken` that must be received for the transaction to proceed.
     * @param pool The address of the pool to be used for swapping.
     */
    function _swapByUniswapV3Router2(uint256 amountIn, uint256 amountOutMin, address pool) internal {
        //--------------------------------------------------------------------------------
        // 1. Approve 'amountIn' of fromToken to the Uniswap V3 Router contract.
        //--------------------------------------------------------------------------------
        _approve(amountIn, _routers[UNISWAP_V3_PROTOCOL]);

        //--------------------------------------------------------------------------------
        // 2. Swap fromToken to toToken using Uniswap V3 Router2 contract.
        //  Struct: ExactInputSingleParams
        //  @param tokenIn: The contract address of the inbound token.
        //  @param tokenOut: The contract address of the outbound token.
        //  @param fee: The fee tier of the pool, used to determine the correct pool contract in which to execute the swap.
        //  @param recipient: The destination address of the outbound token.
        //  @param amountOutMinimum: The minimum amount of the outbound token that must be received for the transaction not to revert.
        //  @param sqrtPriceLimitX96: We set this to zero - which makes this parameter inactive.
        //--------------------------------------------------------------------------------
        IUniswapV3Router02.ExactInputSingleParams memory params = IUniswapV3Router02.ExactInputSingleParams({
            tokenIn: fromToken,
            tokenOut: toToken,
            fee: IUniswapV3Pool(pool).fee(),
            recipient: vault,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0
        });

        bytes memory data = abi.encodeWithSelector(IUniswapV3Router02.exactInputSingle.selector, params);

        //--------------------------------------------------------------------------------
        // 3. Execute the swap using the Uniswap V3 Router2 contract.
        //--------------------------------------------------------------------------------
        IVault(vault).execute(_routers[UNISWAP_V3_PROTOCOL], data, 0);

        //--------------------------------------------------------------------------------
        // 4. Post allowance check to ensure the spender is not allowed to spend.
        //--------------------------------------------------------------------------------
        _checkAllowance(_routers[UNISWAP_V3_PROTOCOL]);
    }

    /**
     * @dev Executes a token swap from `fromToken` to `toToken` using Uniswap V2 router.
     *      This function utilizes the `swapExactTokensForTokens` method in the Uniswap V2 router.
     *      Reference: https://etherscan.io/address/0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
     * @param amountIn The amount of `fromToken` to swap.
     * @param amountOutMin The minimum amount of `toToken` that must be received for the transaction to proceed.
     */
    function _swapByUniswapV2Router2(uint256 amountIn, uint256 amountOutMin) internal {
        //--------------------------------------------------------------------------------
        // 1. Approve 'amountIn' of fromToken to the Uniswap V2 Router contract.
        //--------------------------------------------------------------------------------
        _approve(amountIn, _routers[UNISWAP_V2_PROTOCOL]);

        //--------------------------------------------------------------------------------
        // 2. Swap fromToken to toToken using Uniswap V2 Router2 contract.
        //  @param amountIn: The amount of the input token to send.
        //  @param amountOutMin: The minimum amount of the output token that must be received for the transaction not to revert.
        //  @param pool: An array of token addresses. path.length must be >= 2.
        //  @param Pools for each consecutive pair of addresses must exist and have liquidity.
        //  @param to: The address to receive the output token.
        //  @param deadline: The block timestamp after which the transaction will revert.
        address[] memory pool = new address[](2);
        pool[0] = fromToken;
        pool[1] = toToken;
        bytes memory data = abi.encodeWithSelector(
            IUniswapV2Router02.swapExactTokensForTokens.selector,
            amountIn,
            amountOutMin,
            pool,
            vault,
            block.timestamp
        );

        //--------------------------------------------------------------------------------
        // 3. Execute the swap using the Uniswap V2 Router2 contract.
        //--------------------------------------------------------------------------------
        IVault(vault).execute(_routers[UNISWAP_V2_PROTOCOL], data, 0);

        //--------------------------------------------------------------------------------
        // 4. Post allowance check to ensure the spender is not allowed to spend.
        //--------------------------------------------------------------------------------
        _checkAllowance(_routers[UNISWAP_V2_PROTOCOL]);
    }

    /**
     * @dev Executes a token swap from `fromToken` to `toToken` using the Curve.fi protocol.
     * Reference: https://etherscan.io/address/0x99a58482BD75cbab83b27EC03CA68fF489b5788f
     * Curve method: exchange
     * @param amountIn The amount of input tokens to send for the swap.
     * @param amountOutMin The minimum amount of `toToken` that must be received for the transaction to proceed.
     * @param pool The address of the Curve pool to use for swapping.
     */
    function _swapByCurve(uint256 amountIn, uint256 amountOutMin, address pool) internal {
        //--------------------------------------------------------------------------------
        // 1. Approve 'amountIn' of fromToken to the Curve Router contract.
        //--------------------------------------------------------------------------------
        _approve(amountIn, _routers[CURVE_PROTOCOL]);

        //--------------------------------------------------------------------------------
        // 2. Swap fromToken to toToken using Curve Router contract.
        //  @param swapParams: 2D array of swap，Performs up to 5 swaps in a single transaction，here is 1 swap.
        //  swapParams[n][0] = i, the index of the token to swap from in the n'th pool in `_route`.
        //  swapParams[n][1] = j, the index of the token to swap to in the n'th pool in `_route`.
        //  swapParams[n][2] = swap type, the type of swap to do for the n'th pool in `_route`, 1 for a `exchange`.
        //  swapParams[n][3] in [1, 10]:  stable and stable_ng, reference is not used.
        //--------------------------------------------------------------------------------
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

        // Array of [initial token, pool, token, pool, token, ...] - in this case, only one pool is used.
        address[11] memory route;
        route[0] = fromToken;
        route[1] = pool;
        route[2] = toToken;

        // Array of pools for swaps via zap contracts. This parameter is only needed for swap_type = 3, here is only one pool.
        address[5] memory pools;
        pools[0] = pool;

        bytes memory data = abi.encodeWithSelector(
            ICurveFiRouter.exchange.selector, route, swapParams, amountIn, amountOutMin, pools, vault
        );

        //--------------------------------------------------------------------------------
        // 3. Execute the swap using the Curve Router contract.
        //--------------------------------------------------------------------------------
        IVault(vault).execute(_routers[CURVE_PROTOCOL], data, 0);

        //--------------------------------------------------------------------------------
        // 4. Post allowance check to ensure the spender is not allowed to spend.
        //--------------------------------------------------------------------------------
        _checkAllowance(_routers[CURVE_PROTOCOL]);
    }

    /**
     * @dev Executes a token swap from `fromToken` to `toToken` using the DODO V2 Proxy02.
     * Reference: https://etherscan.io/address/0xa356867fDCEa8e71AEaF87805808803806231FdC
     * DODO method: dodoSwapV2TokenToToken
     * @param amountIn The amount of input tokens to provide for the swap.
     * @param amountOutMin The minimum amount of output tokens required for the transaction to succeed.
     * @param pool The address of the DODO pool to use for the swap.
     */
    function _swapByDODOV2Proxy02(uint256 amountIn, uint256 amountOutMin, address pool) internal {
        //--------------------------------------------------------------------------------
        // 1. Approve 'amountIn' of fromToken to the dodov2 proxyv2 contract.
        //--------------------------------------------------------------------------------
        address approveProxy = IDODOV2ProxyV2(_routers[DODO_PROTOCOL])._DODO_APPROVE_PROXY_();
        address dodoApprove = IDODOAppProxy(approveProxy)._DODO_APPROVE_();
        _approve(amountIn, dodoApprove);

        //--------------------------------------------------------------------------------
        // 2. Swap fromToken to toToken using dodov2 proxyv2 contract.
        //  @param fromToken: The contract address of the inbound token.
        //  @param toToken: The contract address of the outbound token.
        //  @param fromTokenAmount: The amount of the inbound token to swap.
        //  @param minReturnAmount: The minimum amount of the outbound token that must be received for the transaction not to revert.
        //  @param dodoPairs: An array of DODO pairs to use for the swap.
        //  @param directions: An array of directions for each pair in `dodoPairs`. sellBaseToken represents 0, sellQuoteToken represents 1.
        //  @param isIncentive: Whether to enable the DODO incentive model.
        //  @param deadLine: The block timestamp after which the transaction will revert.
        //--------------------------------------------------------------------------------
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

        //--------------------------------------------------------------------------------
        // 3. Execute the swap using the DODO V2 Router contract.
        //--------------------------------------------------------------------------------
        IVault(vault).execute(_routers[DODO_PROTOCOL], data, 0);

        //--------------------------------------------------------------------------------
        // 4. Post allowance check to ensure the spender is not allowed to spend.
        //--------------------------------------------------------------------------------
        _checkAllowance(dodoApprove);
    }

    /**
     * @dev Executes a token swap from `fromToken` to `toToken` using the Balancer V2 Vault.
     * Reference: https://etherscan.io/address/0xBA12222222228d8Ba445958a75a0704d566BF2C8
     * Balancer method: swap
     * @param amountIn The amount of input tokens to provide for the swap.
     * @param amountOutMin The minimum amount of output tokens required for the transaction to succeed.
     * @param pool The address of the Balancer pool to use for the swap.
     */
    function _swapByBalancerV2Vault(uint256 amountIn, uint256 amountOutMin, address pool) internal {
        //--------------------------------------------------------------------------------
        // 1. Approve 'amountIn' of fromToken to the Balancer V2 Vault contract.
        //--------------------------------------------------------------------------------
        _approve(amountIn, _routers[BALANCER_PROTOCOL]);

        //--------------------------------------------------------------------------------
        // 2. Swap fromToken to toToken using Balancer V2 Vault contract.
        //  Struct: SingleSwap
        //  @param poolId: The id of the pool to swap with.
        //  @param kind: The type of swap to perform - either "Out Given Exact In" or "In Given Exact Out".
        //  @param assetIn: The address of the token to swap into the pool.
        //  @param assetOut: The address of the token to receive in return.
        //  @param amount: The meaning of amount depends on the value of kind.
        //  @param GIVEN_IN: The amount of tokens being sent.
        //  @param GIVEN_OUT: The amount of tokens being received.
        //  @param userData: Any additional data which the pool requires to perform the swap.
        //--------------------------------------------------------------------------------
        bytes32 poolId = IBalancerPool(pool).getPoolId();
        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap({
            poolId: poolId,
            kind: IBalancerVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(fromToken),
            assetOut: IAsset(toToken),
            amount: amountIn,
            userData: ""
        });

        //  Struct: FundManagement
        //  @param sender: The address from which tokens will be taken to perform the swap.
        //  @param fromInternalBalance: Whether the swap should use tokens owned by the sender which are already stored in the Vault.
        //  @param recipient: The address to which tokens will be sent to after the swap.
        //  @param toInternalBalance: Whether the tokens should be sent to the recipient or stored within their internal balance within the Vault.
        IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement({
            sender: vault,
            fromInternalBalance: false,
            recipient: payable(vault),
            toInternalBalance: false
        });
        bytes memory data =
            abi.encodeWithSelector(IBalancerVault.swap.selector, singleSwap, funds, amountOutMin, block.timestamp);

        //--------------------------------------------------------------------------------
        // 3. Execute the swap using the Balancer V2 Vault contract.
        //--------------------------------------------------------------------------------
        IVault(vault).execute(_routers[BALANCER_PROTOCOL], data, 0);

        //--------------------------------------------------------------------------------
        // 4. Post allowance check to ensure the spender is not allowed to spend.
        //--------------------------------------------------------------------------------
        _checkAllowance(_routers[BALANCER_PROTOCOL]);
    }

    /**
     * @dev Approves the specified `amountIn` of tokens for the `spender` contract.
     * This ensures the `spender` is permitted to spend the specified amount on behalf of the caller.
     * @param amountIn The amount of input tokens to allow the `spender` to spend.
     * @param spender The address of the contract that will be approved to spend tokens.
     */
    function _approve(uint256 amountIn, address spender) internal {
        require(IERC20(fromToken).balanceOf(vault) >= amountIn, "USR010");

        // Approve 'amountIn' for the spender contract.
        if (IERC20(fromToken).allowance(vault, spender) != amountIn) {
            bytes memory data = abi.encodeWithSelector(IERC20.approve.selector, spender, 0);
            IVault(vault).execute(fromToken, data, 0);
            data = abi.encodeWithSelector(IERC20.approve.selector, spender, amountIn);
            IVault(vault).execute(fromToken, data, 0);
        }
    }

    /**
     * @dev Verifies that the allowance of the `spender` contract for the `fromToken`
     * within the `vault` is set to zero.
     * This is often used as a prerequisite before resetting the allowance to avoid
     * potential race conditions in ERC20 approvals.
     * @param spender The address of the contract whose allowance is being checked.
     */
    function _checkAllowance(address spender) internal view {
        require(IERC20(fromToken).allowance(vault, spender) == 0, "USR017");
    }

    /**
     * @dev Ensures that the provided `protocol` is supported.
     * The function checks against predefined constants for supported protocols:
     * Uniswap V3, Uniswap V2, Curve, DODO, and Balancer.
     * @param protocol The protocol identifier to validate.
     */
    function _checkProtocol(bytes32 protocol) internal pure {
        require(
            protocol == CURVE_PROTOCOL || protocol == UNISWAP_V2_PROTOCOL || protocol == UNISWAP_V3_PROTOCOL
                || protocol == DODO_PROTOCOL || protocol == BALANCER_PROTOCOL,
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
     * @notice Emitted when a token swap operation is successfully completed.
     * @dev This event provides details about the token involved and the amount swapped.
     * @param token The address of the token that was swapped.
     * @param amount The amount of the token that was successfully swapped.
     */
    event SwapSuccessful(address token, uint256 amount);
}
