// File: contracts/interfaces/IBTCLayer2Bridge.sol

// References:
//    1. https://scan.merlinchain.io/address/0x28AD6b7dfD79153659cb44C2155cf7C0e1CeEccC
//    2. https://github.com/MerlinLayer2/BTCLayer2BridgeContract/blob/main/contracts/BTCLayer2Bridge.sol
interface IBTCLayer2Bridge {
    event UnlockNativeToken(    // Emitted by the unlockNativeToken function (which is called by the MTokenSwap.swapMBtc function).
        bytes32 txHash,
        address account,
        uint256 amount
    );

    event LockNativeTokenWithBridgeFee( // Emitted by lockNativeToken function.
        address account,
        uint256 amount,
        string destBtcAddr,
        uint256 bridgeFee
    );

    function lockNativeToken(string memory destBtcAddr) external payable;
    function getBridgeFee(address msgSender, address token) external view returns(uint256);
}
// File: contracts/interfaces/IMTokenSwap.sol

// Reference: https://scan.merlinchain.io/address/0x72A817715f174a32303e8C33cDCd25E0dACfE60b
interface IMTokenSwap {
    event SwapMBtc( // Emitted by swapMBtc function.
        address msgSender,
        bytes32 txHash,
        address tokenMBtc,
        uint256 amount
    );

    function swapMBtc(bytes32 _txHash, uint256 _amount) external;
    function bridgeAddress() external returns (address);
}
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

// File: contracts/contracts/proxies/MBTCProxy.sol

contract MBTCProxy is Ownable {
    address private constant EMPTY_TOKEN = address(0);
    bytes32 private constant BASE_HASH = 0xbeD0000000000000000000000000000000000000000000000000000000000000;

    address public immutable vault;
    address public immutable mBTC;
    address public immutable mTokenSwap;
    address public immutable btcLayer2Bridge;

    uint256 public nonce;

    constructor(address _vault, address _mBTC, address _mTokenSwap) {
        vault = _vault;
        mBTC = _mBTC;
        mTokenSwap = _mTokenSwap;
        btcLayer2Bridge = IMTokenSwap(_mTokenSwap).bridgeAddress();
    }

    receive() external payable {
        revert("value only accepted by the Vault contract");
    }

    /**
     * @dev swap '_amount' M-BTC on the Merlin network (layer 2) to '_amount - getBridgeFee()' BTC on the Bitcoin network (layer 1).
     */
    function swapMBTCToBTC(uint256 _amount, string memory _destBtcAddr) external onlyOwner {
        // 1. Approve '_amount' M-BTC to MTokenSwap contract
        bytes memory data;
        if (IERC20(mBTC).allowance(vault, mTokenSwap) < _amount) {
            data = abi.encodeWithSelector(IERC20.approve.selector, mTokenSwap, _amount);
            IVault(vault).execute(mBTC, data, 0);
        }

        // 2.1 MTokenSwap contract transfers '_amount' M-BTC from Vault contract.
        // 2.2 BTCLayer2Bridge unlocks/transfers '_amount' native BTC to Vault contract.
        data = abi.encodeWithSelector(IMTokenSwap.swapMBtc.selector, getNextTxHash(), _amount);
        IVault(vault).execute(mTokenSwap, data, 0);

        // 3. Lock native BTC of Vault contract with bridge fee on BTCLayer2Bridge contract.
        data = abi.encodeWithSelector(IBTCLayer2Bridge.lockNativeToken.selector, _destBtcAddr);
        IVault(vault).execute(btcLayer2Bridge, data, _amount);

        // 4. Address 'destBtcAddr' receives '_amount - getBridgeFee()' BTC on the Bitcoin network (beyond the Merlin network).
    }

    /**
     * @dev get cross-chain bridge fee required to swap M-BTC to BTC
     */
    function getBridgeFee() public view returns(uint256) {
        return IBTCLayer2Bridge(btcLayer2Bridge).getBridgeFee(vault, EMPTY_TOKEN);
    }

    /**
     * ======================================================================================
     *
     * INTERNAL
     *
     * ======================================================================================
     */

    /**
     * @dev get the next txHash
     */
    function getNextTxHash() internal returns (bytes32 txHash) {
        nonce += 1;
        txHash = BASE_HASH | bytes32(nonce);
    }
}