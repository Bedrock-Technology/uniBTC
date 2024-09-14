// File: contracts/interfaces/IVault.sol

interface IVault {
    function execute(
        address target,
        bytes memory data,
        uint256 value
    ) external returns (bytes memory);
}

// File: contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/interfaces/IUniswap.sol

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
interface IUniswapWbtcFbtcPool {
    function fee() external view returns (uint24);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// File: contracts/contracts/proxies/WBTCSwapFBTCProxy.sol

contract WBTCSwapFBTCProxy is Ownable {
    address public immutable BEDROCK_VAULT;
    address public immutable WBTC;
    address public immutable FBTC;
    address public immutable UNISWAP_V3_ROUTER_02;
    address public immutable UNISWAP_WBTC_FBTC_POOL;
    uint24 public immutable UNISWAP_WBTC_FBTC_FEE;
    uint256 public constant SLIPPAGE_RANGE = 10000;
    uint256 public constant SLIPPAGE_DEFAULT = 10;

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
        IVault(BEDROCK_VAULT).execute(UNISWAP_V3_ROUTER_02, data, 0);
    }
}