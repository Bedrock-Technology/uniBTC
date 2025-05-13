// SPDX-License-Identifier: MIT

// interfaces/IBalancer.sol

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// Reference: https://etherscan.io/address/0xBA12222222228d8Ba445958a75a0704d566BF2C8
// https://docs.balancer.fi/reference/swaps/single-swap.html
interface IBalancerVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);
}

// Reference: https://etherscan.io/address/0xdd59f89b5b07b7844d72996fc9d83d81acc82196
interface IBalancerPool {
    /**
     * @dev Returns this Pool's ID, used when interacting with the Vault (to e.g. join the Pool or swap with it).
     */
    function getPoolId() external view returns (bytes32);
}

// interfaces/ICurve.sol

// Reference: https://etherscan.io/address/0x99a58482BD75cbab83b27EC03CA68fF489b5788f
interface ICurveFiRouter {
    function exchange(
        address[11] calldata _route,
        uint256[5][5] calldata _swap_params,
        uint256 _amount,
        uint256 _min_dy,
        address[5] calldata _pools,
        address _receiver
    ) external payable returns (uint256 amountOut);
}

//Reference: https://etherscan.io/address/0x839d6bDeDFF886404A6d7a788ef241e4e28F4802
interface ICurvePool {
    function fee() external view returns (uint256);
    function N_COINS() external view returns (uint256);
    function coins(uint256 index) external view returns (address);
}

// interfaces/IERC20Symbol.sol

// Interface for ERC20 symbol
interface IERC20Symbol {
    function symbol() external view returns (string memory);
}

// interfaces/IUniswapV2.sol

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

// interfaces/IUniswapV3.sol

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

// interfaces/IVault.sol

interface IVault {
    function execute(
        address target,
        bytes memory data,
        uint256 value
    ) external returns (bytes memory);
}

// lib/OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/token/ERC20/IERC20.sol

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

// lib/OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/utils/Context.sol

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

// interfaces/IDODOV2.sol

// Reference: https://etherscan.io/address/0xa356867fDCEa8e71AEaF87805808803806231FdC
//https://github.com/DODOEX/dodo-example/blob/main/solidity/contracts/DODOProxyIntegrate.sol
interface IDODOV2ProxyV2 {
    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

    function _DODO_APPROVE_PROXY_() external view returns (address);
}

// Reference: https://etherscan.io/address/0xD39DFbfBA9E7eccd813918FfbDa10B783EA3b3C6
interface IDODOV2Pool {
    function _BASE_TOKEN_() external view returns (IERC20);
}

// Reference: https://etherscan.io/address/0x335aC99bb3E51BDbF22025f092Ebc1Cf2c5cC619
interface IDODOAppProxy {
    function _DODO_APPROVE_() external view returns (address);
}

// lib/OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/access/Ownable.sol

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

// lib/OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// lib/OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// contracts/proxies/SwapProxy.sol

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

    /// @notice Token decimals for 18 decimal places.
    uint8 public constant TOKEN_18_DECIMAL = 18;

    /// @notice Token decimals for 8 decimal places.
    uint8 public constant TOKEN_8_DECIMAL = 8;

    /// @notice Converts a token amount between two decimal precisions.
    uint256 public constant TOKEN_DECIMAL_8_BETWEEN_18_EXCHANGE_PRECISION = 1e10;

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
        uint8 fromTokenDecs = ERC20(_fromToken).decimals();
        require(fromTokenDecs == TOKEN_18_DECIMAL || fromTokenDecs == TOKEN_8_DECIMAL, "SYS003");
        uint8 toTokenDecs = ERC20(_toToken).decimals();
        require(toTokenDecs == TOKEN_18_DECIMAL || toTokenDecs == TOKEN_8_DECIMAL, "SYS003");
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
     *      This describes the conversion from the `fromToken` to the `toToken`,
     *      showing their respective symbols (e.g., "ETH -> USDT").
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
        uint256 amountToTokenIn = _amounts(amountIn);
        require(amountToTokenIn > 0, "USR014");
        uint256 amountOutMin;

        //--------------------------------------------------------------------------------
        // 1. Calculate the minimum amount of `toToken` that must be received for the swap.
        //--------------------------------------------------------------------------------
        if (!forward) {
            amountOutMin = (amountToTokenIn * (SLIPPAGE_RANGE + slippage)) / SLIPPAGE_RANGE;
        } else {
            amountOutMin = (amountToTokenIn * (SLIPPAGE_RANGE - slippage)) / SLIPPAGE_RANGE;
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
            IUniswapV2Router02.swapExactTokensForTokens.selector, amountIn, amountOutMin, pool, vault, block.timestamp
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
     *      Reference: https://etherscan.io/address/0x99a58482BD75cbab83b27EC03CA68fF489b5788f
     *      Curve method: exchange
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
     *      Reference: https://etherscan.io/address/0xa356867fDCEa8e71AEaF87805808803806231FdC
     *      DODO method: dodoSwapV2TokenToToken
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
     *      Reference: https://etherscan.io/address/0xBA12222222228d8Ba445958a75a0704d566BF2C8
     *      Balancer method: swap
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
     *      This ensures the `spender` is permitted to spend the specified amount on behalf of the caller.
     * @param amountIn The amount of input tokens to allow the `spender` to spend.
     * @param spender The address of the contract that will be approved to spend tokens.
     */
    function _approve(uint256 amountIn, address spender) internal {
        require(IERC20(fromToken).balanceOf(vault) >= amountIn, "USR010");

        // Approve 'amountIn' for the spender contract.
        bytes memory data = abi.encodeWithSelector(IERC20.approve.selector, spender, 0);
        IVault(vault).execute(fromToken, data, 0);
        data = abi.encodeWithSelector(IERC20.approve.selector, spender, amountIn);
        IVault(vault).execute(fromToken, data, 0);
    }

    /**
     * @dev Verifies that the allowance of the `spender` contract for the `fromToken`
     *      within the `vault` is set to zero.
     *      This is often used as a prerequisite before resetting the allowance to avoid
     *      potential race conditions in ERC20 approvals.
     * @param spender The address of the contract whose allowance is being checked.
     */
    function _checkAllowance(address spender) internal view {
        require(IERC20(fromToken).allowance(vault, spender) == 0, "USR017");
    }

    /**
     * @dev Ensures that the provided `protocol` is supported.
     *      The function checks against predefined constants for supported protocols:
     *      Uniswap V3, Uniswap V2, Curve, DODO, and Balancer.
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
     * @dev Converts a token amount between two decimal precisions.
     * @param amountIn The amount of input tokens to provide for the swap.
     * @return The converted amount of tokens based on the token precision.
     */
    function _amounts(uint256 amountIn) internal view returns (uint256) {
        uint8 fromTokenDecs = ERC20(fromToken).decimals();
        uint8 toTokenDecs = ERC20(toToken).decimals();
        if (fromTokenDecs == toTokenDecs) {
            return (amountIn);
        }
        if (toTokenDecs == TOKEN_8_DECIMAL) {
            return (amountIn / TOKEN_DECIMAL_8_BETWEEN_18_EXCHANGE_PRECISION);
        }
        return (amountIn * TOKEN_DECIMAL_8_BETWEEN_18_EXCHANGE_PRECISION);
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
