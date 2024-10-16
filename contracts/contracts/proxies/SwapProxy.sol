// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IUniswapV3.sol";
import "../../interfaces/IUniswapV2.sol";
import "../../interfaces/ICurve.sol";
import "../../interfaces/IERC20Symbol.sol";

contract SwapProxy is Ownable {
    ///dfine slippage range
    uint256 public constant SLIPPAGE_RANGE = 10000;
    ///default slippage
    uint256 public constant SLIPPAGE_DEFAULT = 50;
    ///max slippage
    uint256 public constant SLIPPAGE_MAX = 100;
    ///define uniswapV2 protocol
    bytes32 public constant UNISWAP_V2_PROTOCOL =
        keccak256("UNISWAP_V2_PROTOCOL");
    ///define uniswapV3 protocol
    bytes32 public constant UNISWAP_V3_PROTOCOL =
        keccak256("UNISWAP_V3_PROTOCOL");
    ///define curve protocol
    bytes32 public constant CURVE_PROTOCOL = keccak256("CURVE_PROTOCOL");
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
     */
    function swapToken(
        uint256 amountIn,
        address pool,
        uint256 slippage
    ) external onlyOwner {
        require(slippage < SLIPPAGE_MAX, "USR011");
        _swap(amountIn, slippage, pool);
    }

    /**
     * @dev Receive an exact amount of input token for as few output tokens as possible
     * @param amountIn The amount of input token to send.
     * @param pool The pool using for swapping
     * The default slippage(0.5%) for the swap.
     */
    function swapToken(uint256 amountIn, address pool) external onlyOwner {
        _swap(amountIn, SLIPPAGE_DEFAULT, pool);
    }

    /**
     * @dev add an exact router of special protocol
     * @param router the address of router
     * @param protocol only support(uniswapV3,uniswapV2,curve)
     */
    function addRouter(address router, bytes32 protocol) public onlyOwner {
        _checkProtocol(protocol);
        require(_routers[protocol] == address(0x0), "USR020");
        _routers[protocol] = router;
    }

    /**
     * @dev add an exact pool of special protocol
     * @param pool the address of pool
     * @param protocol only support(uniswapV3,uniswapV2,curve)
     */
    function addPool(address pool, bytes32 protocol) public onlyOwner {
        _checkProtocol(protocol);
        require(!_poolsInfo[pool].existed, "USR020");
        _pools.push(pool);
        _poolsInfo[pool].protocol = protocol;
        _poolsInfo[pool].isValid = true;
        _poolsInfo[pool].existed = true;
    }

    /**
     * @dev disable an exact pool of special protocol
     * @param pool the address of pool
     * @param protocol only support(uniswapV3,uniswapV2,curve)
     */
    function disablePool(address pool, bytes32 protocol) public onlyOwner {
        _checkProtocol(protocol);
        require(_poolsInfo[pool].existed, "USR022");
        _poolsInfo[pool].isValid = false;
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
    function _swap(uint256 amountIn, uint256 slippage, address pool) internal {
        require(_poolsInfo[pool].isValid, "USR021");
        uint256 amountOutMin = (amountIn * (SLIPPAGE_RANGE - slippage)) /
            SLIPPAGE_RANGE;
        uint256 vaultToTokenBalanceBefore = IERC20(toToken).balanceOf(
            bedrockVault
        );
        if (_poolsInfo[pool].protocol == UNISWAP_V3_PROTOCOL) {
            _swapByUniswapV3Router2(amountIn, amountOutMin, pool);
        } else if (_poolsInfo[pool].protocol == UNISWAP_V2_PROTOCOL) {
            _swapByUniswapV2Router2(amountIn, amountOutMin);
        } else if (_poolsInfo[pool].protocol == CURVE_PROTOCOL) {
            _swapByCurve(amountIn, amountOutMin, pool);
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
     */
    function _swapByUniswapV3Router2(
        uint256 amountIn,
        uint256 amountOutMin,
        address pool
    ) internal {
        // 1. Approve 'amountIn' fromToken to uniswapV3Router02 contract
        _approve(amountIn, _routers[UNISWAP_V3_PROTOCOL]);
        // 2. swap fromToken to toToken using uniswapV3Router02 contract.
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
    }

    /**
     * @dev call uniswap v2 router2 to swap fromToken to toToken
     */
    function _swapByUniswapV2Router2(
        uint256 amountIn,
        uint256 amountOutMin
    ) internal {
        // 1. Approve 'amountIn' fromToken to uniswapV2Router02 contract
        _approve(amountIn, _routers[UNISWAP_V2_PROTOCOL]);
        // 2. swap fromToken to toToken using uniswapV2Router02 contract.
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
    }

    /**
     * @dev call curve router to swap fromToken to toToken
     */
    function _swapByCurve(
        uint256 amountIn,
        uint256 amountOutMin,
        address pool
    ) internal {
        // 1. Approve 'amountIn' fromToken to curve router contract
        _approve(amountIn, _routers[CURVE_PROTOCOL]);
        // 2. swap fromToken to toToken using curve router contract.
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
        address[11] memory route;
        route[0] = fromToken;
        route[1] = pool;
        route[2] = toToken;
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
    }

    function _approve(uint256 amountIn, address router) internal {
        require(
            IERC20(fromToken).balanceOf(bedrockVault) >= amountIn,
            "USR010"
        );
        // 1. Approve '_amount' to router contract
        if (IERC20(fromToken).allowance(bedrockVault, router) < amountIn) {
            bytes memory data = abi.encodeWithSelector(
                IERC20.approve.selector,
                router,
                amountIn
            );
            IVault(bedrockVault).execute(fromToken, data, 0);
        }
    }

    /**
     * @dev only support uniswapV3, uniswapV2, curve protocol
     */
    function _checkProtocol(bytes32 protocol) internal pure {
        require(
            protocol == CURVE_PROTOCOL ||
                protocol == UNISWAP_V2_PROTOCOL ||
                protocol == UNISWAP_V3_PROTOCOL,
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
