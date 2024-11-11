// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../../../interfaces/IMintableContract.sol";
import "../../../../interfaces/IVault.sol";

contract DelayRedeemRouter is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    /**
     * @notice the duration time in 30 days (60 * 60 * 24 * 30 = 2,592,000)
     */
    uint256 public constant MAX_REDEEM_DELAY_DURATION_TIME = 2592000;

    /**
     * @notice the maximum amount of unibtc that can be burned setting in a single day for each specific btc token
     */
    uint256 public constant DAY_MAX_ALLOWED_CAP = 100e8;

    /**
     * @notice define redeem manage rate range, precision to ten thousandths
     */
    uint256 public constant REDEEM_MANAGE_RANGE = 10000;

    /**
     * @notice default redeem manage rate(2%)
     */
    uint256 public constant REDEEM_MANAGE_DEFAULT = 200;

    /**
     * @notice Delay enforced by this contract for completing any delayedRedeem, Measured in timestamp,
     * and adjustable by this contract's owner,up to a maximum of `MAX_REDEEM_DELAY_DURATION_TIME`.
     * Minimum value is 0 (i.e. no delay enforced).
     */
    uint256 public redeemDelayTimestamp;

    /**
     * @notice The address of the ERC20 uniBTC token.
     */
    address public uniBTC;

    /**
     * @notice The address of the Vault contract.
     */
    address public vault;

    /**
     * @notice struct used to store delayed redeem information
     * @param amount the amount of the delayed redeem for a specific btc token
     * @param timestampCreated the timestamp at which the `DelayedRedeem` was created
     * @param token the address of a specific btc token
     */
    struct DelayedRedeem {
        uint224 amount;
        uint32 timestampCreated;
        address token;
    }

    /**
     * @notice struct used to store a single users delayedRedeem data
     * @param delayedRedeemsCompleted the number of delayedRedeems that have been completed
     * @param delayedRedeems an array of delayedRedeems
     */
    struct UserDelayedRedeems {
        uint256 delayedRedeemsCompleted;
        DelayedRedeem[] delayedRedeems;
    }

    /**
     * @notice define a structure for temporary storage of the debt btc token type and corresponding cumulative amounts
     * @param token the address of a specific btc token
     * @param amount the redeem amount of a specific btc token
     */
    struct DebtTokenAmount {
        address token;
        uint256 amount;
    }

    /**
     * @notice struct used to store the total amount of debt and the total amount of claimed debt for a specific btc token
     * @param totalAmount the total amount of debt for a specific btc token
     * @param claimedAmount the total amount of claimed debt for a specific btc token
     */
    struct TokenDebtInfo {
        uint256 totalAmount;
        uint256 claimedAmount;
    }

    /**
     * @notice user => struct storing all delayedRedeem info.
     * Marked as internal with an external getter function named `userRedeems`
     */
    mapping(address => UserDelayedRedeems) internal _userRedeems;

    /**
     * @notice token => struct tracking different token debt.
     */
    mapping(address => TokenDebtInfo) public tokenDebts;

    /**
     * @notice mapping to store the whitelist status of an account.
     * only in whitelist addresses can redeem using unibtc
     */
    mapping(address => bool) private whitelist;

    /**
     * @notice mapping to store a specific btc token status.
     * only in btclist tokens(wrapped or native BTC) can redeem using unibtc
     */
    mapping(address => bool) private btclist;

    /**
     * @notice flag to enable/disable the whitelist feature.
     * If enabled, only in whitelist addresses can redeem using unibtc.
     */
    bool public whitelistEnabled;

    /**
     * @notice the max free cap for tokens once redeem
     */
    mapping(address => uint256) public maxFreeQuotas;

    /**
     * @notice the base redeem quota of the different btc token in duration history timestamp
     */
    mapping(address => uint256) public baseQuotas;

    /**
     * @notice redeem specific btc token amount per second
     */
    mapping(address => uint256) public numTokensPerSecond;

    /**
     * @notice record the last rebase timestamp for each specific btc token
     */
    mapping(address => uint256) public lastRebaseTimestamps;

    /**
     * @notice define the native BTC token
     */
    address public constant NATIVE_BTC =
        address(0xbeDFFfFfFFfFfFfFFfFfFFFFfFFfFFffffFFFFFF);

    /**
     * @notice using for converting some wrapped BTC to the 18 decimals
     */
    uint256 public constant EXCHANGE_RATE_BASE = 1e10;

    /**
     * @notice principal redeem period
     */
    uint256 public redeemPrincipalDelayTimestamp;

    /**
     * @notice mapping to store the blacklist status of an account.
     * only not in blacklist accounts can redeem using unibtc
     */
    mapping(address => bool) private blacklist;

    /**
     * @notice mapping to store the pausedTokenlist status of an address.
     * only not in pausedTokenlist tokens, user can create redeem using unibtc and claim the specific btc token.
     */
    mapping(address => bool) private pausedTokenlist;

    /**
     * @notice track the redeem manage rate for the contract
     */
    uint256 public redeemManageRate;

    /**
     * @notice track the redeem manage fee for the contract
     */
    uint256 public redeemManageFee;

    receive() external payable {}

    /**
     * ======================================================================================
     *
     * CONSTRUCTOR
     *
     * ======================================================================================
     */

    /**
     *  @dev disables the ability to call any other initializer functions.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * ======================================================================================
     *
     * MODIFIERS
     *
     * ======================================================================================
     */

    /**
     * @dev modifier to check if the caller is whitelisted
     */
    modifier onlyWhitelisted() {
        require(!whitelistEnabled || whitelist[msg.sender], "USR009");
        _;
    }

    /**
     * @dev modifier to check if the caller is not blacklisted
     */
    modifier onlyNotBlacklisted() {
        require(!blacklist[msg.sender], "USR009");
        _;
    }

    /**
     * ======================================================================================
     *
     * ADMIN
     *
     * ======================================================================================
     */

    /**
     * @notice admin-only function.
     * @param _defaultAdmin the default admin address(RBAC)
     * @param _uniBTC the address of the ERC20 uniBTC token
     * @param _vault the address of the Bedrock Vault contract
     * @param _redeemDelayTimestamp the delay time for claiming a delayedRedeem
     * @param _whitelistEnabled the status of the whitelist feature
     */
    function initialize(
        address _defaultAdmin,
        address _uniBTC,
        address _vault,
        uint256 _redeemDelayTimestamp,
        bool _whitelistEnabled
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        require(_defaultAdmin != address(0x0), "SYS001");
        require(_uniBTC != address(0x0), "SYS001");
        require(_vault != address(0x0), "SYS001");

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(PAUSER_ROLE, _defaultAdmin);

        uniBTC = _uniBTC;
        vault = _vault;
        _setWhitelistEnabled(_whitelistEnabled);
        _setRedeemPrincipalDelayTimestamp(MAX_REDEEM_DELAY_DURATION_TIME);
        _setRedeemDelayTimestamp(_redeemDelayTimestamp);
        _setRedeemManageRate(REDEEM_MANAGE_DEFAULT);
    }

    /**
     * @dev pause the contract
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev unpause the contract
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev set a new delay redeem block timestamp for the contract
     * @param _newValue the new value for the delay redeem block timestamp,
     * after the delay redeem block timestamp, the user can claim the delayed redeem
     */
    function setRedeemDelayTimestamp(
        uint256 _newValue
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRedeemDelayTimestamp(_newValue);
    }

    /**
     * @dev add a new wrapped or native btc token in btclist for the contract
     * @param _tokens the list of the wrapped or native btc token,
     * user can redeem using unibtc for the tokens in btclist
     */
    function addToBtclist(
        address[] calldata _tokens
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            btclist[_tokens[i]] = true;
        }
        emit BtclistAdded(_tokens);
    }

    /**
     * @dev remove a token from btclist for the contract
     * @param _tokens the list of the wrapped or native btc token,
     * user can't redeem using unibtc for the tokens in btclist
     */
    function removeFromBtclist(
        address[] calldata _tokens
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            btclist[_tokens[i]] = false;
        }
        emit BtclistRemoved(_tokens);
    }

    /**
     * @dev set the whitelistEnabled for the contract
     * @param _enabled the new value for the whitelistEnabled,
     * true means only in whitelist accounts can redeem using unibtc,
     * false means all accounts can redeem using unibtc
     */
    function setWhitelistEnabled(
        bool _enabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setWhitelistEnabled(_enabled);
    }

    /**
     * @dev add some accounts in whitelist for the contract
     * @param _accounts the accounts list for the whitelist,
     * only the accounts in the whitelist can redeem using unibtc
     */
    function addToWhitelist(
        address[] calldata _accounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = true;
        }
        emit WhitelistAdded(_accounts);
    }

    /**
     * @dev remove some accounts from whitelist for the contract
     * @param _accounts the accounts list removing in the whitelist,
     * these accounts can not redeem using unibtc
     */
    function removeFromWhitelist(
        address[] calldata _accounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = false;
        }
        emit WhitelistRemoved(_accounts);
    }

    /**
     * @dev add some tokens to the paused list for the contract
     * @param _tokens the tokens list for the pausedTokenlist,
     * these tokens can not used to be redeemed using unibtc and claimed.
     */
    function addToPausedTokenlist(
        address[] calldata _tokens
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            pausedTokenlist[_tokens[i]] = true;
        }
        emit PausedTokenlistAdded(_tokens);
    }

    /**
     * @dev remove some tokens from the paused list for the contract
     * @param _tokens the tokens list for removing in the pausedTokenlist
     * these tokens resume to be redeemed using unibtc and claimed.
     */
    function removeFromPausedTokenlist(
        address[] calldata _tokens
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            pausedTokenlist[_tokens[i]] = false;
        }
        emit PausedTokenlistRemoved(_tokens);
    }

    /**
     * @dev set the max free quota for the each redeem token type
     * @param _tokens the list of the token address
     * @param _quotas the list of the max free quota for each specific btc token
     */
    function setMaxFreeQuotas(
        address[] calldata _tokens,
        uint256[] calldata _quotas
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokens.length == _quotas.length, "SYS006");
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_quotas[i] < DAY_MAX_ALLOWED_CAP, "USR013");
            emit MaxFreeQuotasSet(
                _tokens[i],
                maxFreeQuotas[_tokens[i]],
                _quotas[i]
            );
            maxFreeQuotas[_tokens[i]] = _quotas[i];
        }
    }

    /**
     * @dev withdraw the manage fee from the contract
     * @param amount the amount of the manage fee
     * @param recipient the recipient address of the manage fee
     */
    function withdrawManageFee(uint256 amount, address recipient)  external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount <= redeemManageFee, "USR003");
        redeemManageFee -= amount;
        IERC20(uniBTC).safeTransfer(recipient, amount);
        emit ManageFeeWithdrawn(recipient, amount);
    }

    /**
     * @dev set the redeem amount persecond for each specific btc token
     * @param _tokens the list of the specific btc tokens
     * @param _quotas the list of the redeem amount persecond for each specific btc token
     */
    function setNumTokensPerSecond(
        address[] calldata _tokens,
        uint256[] calldata _quotas
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokens.length == _quotas.length, "SYS006");
        for (uint256 i = 0; i < _tokens.length; i++) {
            // this time need using old quota per second to rebase quota and timestamp
            _rebase(_tokens[i]);
            emit NumTokensPerSecondSet(
                _tokens[i],
                numTokensPerSecond[_tokens[i]],
                _quotas[i]
            );
            numTokensPerSecond[_tokens[i]] = _quotas[i];
        }
    }

    /**
     * @dev set a new delay principal redeem block timestamp for the contract
     * @param _newValue the new value for the delay principal redeem block timestamp,
     * after the delay principal redeem block timestamp, the user can claim the principal
     */
    function setRedeemPrincipalDelayTimestamp(
        uint256 _newValue
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRedeemPrincipalDelayTimestamp(_newValue);
    }

    /**
     * @dev add some accounts in blacklist for the contract
     * @param _accounts the accounts list for the blacklist,
     * the accounts in the blacklist can not claim the delayed redeem
     */
    function addToBlacklist(
        address[] calldata _accounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            blacklist[_accounts[i]] = true;
        }
        emit BlacklistAdded(_accounts);
    }

    /**
     * @dev remove some accounts from blacklist for the contract
     * @param _accounts the accounts list removing in the blacklist,
     * the accounts can claim the delayed redeem
     */
    function removeFromBlacklist(
        address[] calldata _accounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            blacklist[_accounts[i]] = false;
        }
        emit BlacklistRemoved(_accounts);
    }

    /**
     * @dev set the redeem manage rate for the contract
     * @param _newValue the new value for the redeem manage rate,
     * the redeem manage rate is used to calculate the redeem manage fee
     */
    function setRedeemManageRate(uint256 _newValue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRedeemManageRate(_newValue);
    }

    /**
     * ======================================================================================
     *
     * EXTERNAL FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * @notice creates a delayed redeem for `amount` to the `msg.sender`.
     * @dev need to check whether the amount provided meets the amount redeemed by the user
     * @param token the specific btc token
     * @param amount the specific btc token delayed redeem amount
     */
    function createDelayedRedeem(
        address token,
        uint256 amount
    ) external nonReentrant whenNotPaused onlyWhitelisted {
        require(btclist[token] && !pausedTokenlist[token], "SYS003");
        uint256 quota = _getQuota(token);
        require(quota >= amount + tokenDebts[token].totalAmount, "USR010");

        // this time need to rebase quota and timestamp
        _rebase(token);

        //lock unibtc in the contract
        IERC20(uniBTC).safeTransferFrom(msg.sender, address(this), amount);
        if (amount != 0) {
            // user bill need to pay the redeem manage fee
            uint224 userRedeemAmount = uint224(amount * (REDEEM_MANAGE_RANGE - redeemManageRate) / REDEEM_MANAGE_RANGE);
            redeemManageFee += amount - userRedeemAmount;

            DelayedRedeem memory delayedRedeem = DelayedRedeem({
                amount: userRedeemAmount,
                timestampCreated: uint32(block.timestamp),
                token: token
            });
            _userRedeems[msg.sender].delayedRedeems.push(delayedRedeem);

            tokenDebts[token].totalAmount += userRedeemAmount;

            emit DelayedRedeemCreated(
                msg.sender,
                token,
                userRedeemAmount,
                _userRedeems[msg.sender].delayedRedeems.length - 1,
                redeemManageRate
            );
        }
    }

    /**
     * @notice called in order to claim delayed redeem made to msg.sender that have passed the `redeemDelayTimestamp` period.
     * @dev the caller of this function can control when the funds are sent to msg.sender once the redeem becomes claimable.
     * @param maxNumberOfDelayedRedeemsToClaim used to limit the maximum number of delayedRedeems to loop through claiming.
     */
    function claimDelayedRedeems(
        uint256 maxNumberOfDelayedRedeemsToClaim
    ) external nonReentrant whenNotPaused onlyNotBlacklisted {
        _claimDelayedRedeems(msg.sender, maxNumberOfDelayedRedeemsToClaim);
    }

    /**
     * @notice called in order to claim delayed redeem made to the caller that have passed the `redeemDelayTimestamp` period.
     */
    function claimDelayedRedeems()
        external
        nonReentrant
        whenNotPaused
        onlyNotBlacklisted
    {
        _claimDelayedRedeems(msg.sender, type(uint256).max);
    }

    /**
     * @notice called in order to claim delayed redeem made to msg.sender that have passed the `redeemPrincipalDelayTimestamp` period.
     * @param maxNumberOfDelayedRedeemsToClaim used to limit the maximum number of delayedRedeems to loop through claiming.
     * @dev that the caller of this function can control when the funds are sent to msg.sender once the principal becomes claimable.
     */
    function claimPrincipals(
        uint256 maxNumberOfDelayedRedeemsToClaim
    ) external nonReentrant whenNotPaused onlyNotBlacklisted {
        _claimPrincipals(msg.sender, maxNumberOfDelayedRedeemsToClaim);
    }

    /**
     * @notice called in order to claim delayed redeem made to the caller that have passed the `redeemPrincipalDelayTimestamp` period.
     */
    function claimPrincipals()
        external
        nonReentrant
        whenNotPaused
        onlyNotBlacklisted
    {
        _claimPrincipals(msg.sender, type(uint256).max);
    }

    /**
     * @notice getter function for the mapping `_userRedeems`
     * @param user the account had created the delayedRedeem
     * return the UserDelayedRedeems struct for the user
     */
    function userRedeems(
        address user
    ) external view returns (UserDelayedRedeems memory) {
        return _userRedeems[user];
    }

    /**
     * @notice getter function for fetching the delayedRedeem at the `index`th entry from the `_userRedeems[user].delayedRedeems` array
     * @param user the account had created the delayedRedeem
     * @param index the index of the delayedRedeem in the `_userRedeems[user].delayedRedeems` array
     * return the DelayedRedeem struct for the delayedRedeem at the `index`th entry
     */
    function userDelayedRedeemByIndex(
        address user,
        uint256 index
    ) external view returns (DelayedRedeem memory) {
        return _userRedeems[user].delayedRedeems[index];
    }

    /**
     * @notice getter function for fetching the length of the delayedRedeems array of a specific user
     * @param user the account had created the delayedRedeem
     * return the length of the delayedRedeems array of the user
     */
    function userRedeemsLength(address user) external view returns (uint256) {
        return _userRedeems[user].delayedRedeems.length;
    }

    /**
     * @notice convenience function for checking whether or not the delayedRedeem at the `index`th entry from
     * the `_userRedeems[user].delayedRedeems` array is currently claimable
     * @param user the account had created the delayedRedeem
     * @param index the index of the delayedRedeem in the `_userRedeems[user].delayedRedeems` array
     * return true if the delayedRedeem at the `index`th entry is currently claimable, false otherwise
     */
    function canClaimDelayedRedeem(
        address user,
        uint256 index
    ) external view returns (bool) {
        return ((index >= _userRedeems[user].delayedRedeemsCompleted) &&
            (block.timestamp >=
                _userRedeems[user].delayedRedeems[index].timestampCreated +
                    redeemDelayTimestamp));
    }

    /**
     * @notice convenience function for checking whether or not the delayedRedeem at the `index`th entry from
     * the `_userRedeems[user].delayedRedeems` array is currently principal claimable
     * @param user the account had created the delayedRedeem
     * @param index the index of the delayedRedeem in the `_userRedeems[user].delayedRedeems` array
     * return true if the delayedRedeem at the `index`th entry is currently principal claimable, false otherwise
     */
    function canClaimDelayedRedeemPrincipal(
        address user,
        uint256 index
    ) external view returns (bool) {
        return ((redeemPrincipalDelayTimestamp > redeemDelayTimestamp &&
            index >= _userRedeems[user].delayedRedeemsCompleted) &&
            (block.timestamp >=
                _userRedeems[user].delayedRedeems[index].timestampCreated +
                    redeemPrincipalDelayTimestamp));
    }

    /**
     * @notice getter function to get all delayedRedeems of the `user`
     * @param user the account had created the delayedRedeem
     * return an array of DelayedRedeem structs for all not claimed delayedRedeems of the user
     */
    function getUserDelayedRedeems(
        address user
    ) external view returns (DelayedRedeem[] memory) {
        uint256 delayedRedeemsCompleted = _userRedeems[user]
            .delayedRedeemsCompleted;
        uint256 totalDelayedRedeems = _userRedeems[user].delayedRedeems.length;
        uint256 userDelayedRedeemsLength = totalDelayedRedeems -
            delayedRedeemsCompleted;
        DelayedRedeem[] memory userDelayedRedeems = new DelayedRedeem[](
            userDelayedRedeemsLength
        );
        for (uint256 i = 0; i < userDelayedRedeemsLength; i++) {
            userDelayedRedeems[i] = _userRedeems[user].delayedRedeems[
                delayedRedeemsCompleted + i
            ];
        }
        return userDelayedRedeems;
    }

    /**
     * @notice getter function to get all delayedRedeems that are currently claimable by the `user`
     * @param user the account had created the delayedRedeem
     * return an array of DelayedRedeem structs for all claimable delayedRedeems of the user
     */
    function getClaimableUserDelayedRedeems(
        address user
    ) external view returns (DelayedRedeem[] memory) {
        uint256 delayedRedeemsCompleted = _userRedeems[user]
            .delayedRedeemsCompleted;
        uint256 totalDelayedRedeems = _userRedeems[user].delayedRedeems.length;
        uint256 userDelayedRedeemsLength = totalDelayedRedeems -
            delayedRedeemsCompleted;

        uint256 firstNonClaimableRedeemIndex = userDelayedRedeemsLength;

        for (uint256 i = 0; i < userDelayedRedeemsLength; i++) {
            DelayedRedeem memory delayedRedeem = _userRedeems[user]
                .delayedRedeems[delayedRedeemsCompleted + i];
            // check if delayedRedeem can be claimed. break the loop as soon as a delayedRedeem can not be claimed
            if (
                block.timestamp <
                delayedRedeem.timestampCreated + redeemDelayTimestamp
            ) {
                firstNonClaimableRedeemIndex = i;
                break;
            }
        }
        uint256 numberOfClaimableRedeems = firstNonClaimableRedeemIndex;
        DelayedRedeem[] memory claimableDelayedRedeems = new DelayedRedeem[](
            numberOfClaimableRedeems
        );

        if (numberOfClaimableRedeems != 0) {
            for (uint256 i = 0; i < numberOfClaimableRedeems; i++) {
                claimableDelayedRedeems[i] = _userRedeems[user].delayedRedeems[
                    delayedRedeemsCompleted + i
                ];
            }
        }
        return claimableDelayedRedeems;
    }

    /**
     * @notice get a specific btc token available redeemed cap
     */
    function getAvailableCap(address token) external view returns (uint256) {
        if (btclist[token]) {
            return (_getQuota(token) - tokenDebts[token].totalAmount);
        }
        return (0);
    }

    /**
     * @dev check the account is in whitelist or not
     */
    function isWhitelisted(address account) external view returns (bool) {
        return whitelist[account];
    }

    /*
     * @dev check the specific btc token is in btclist or not
     */
    function isBtclisted(address token) external view returns (bool) {
        return btclist[token];
    }

    /**
     * @dev check the account is in blacklist or not
     */
    function isBlacklisted(address account) external view returns (bool) {
        return blacklist[account];
    }

    /**
     * ======================================================================================
     *
     * INTERNAL FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * @notice internal function for changing the value of `redeemDelayTimestamp`. Also performs sanity check and emits an event.
     */
    function _setRedeemDelayTimestamp(uint256 newValue) internal {
        require(newValue <= MAX_REDEEM_DELAY_DURATION_TIME, "USR012");
        require(newValue < redeemPrincipalDelayTimestamp, "USR019");
        emit RedeemDelayTimestampSet(redeemDelayTimestamp, newValue);
        redeemDelayTimestamp = newValue;
    }

    /**
     * @notice internal function for changing the value of `redeemPrincipalDelayTimestamp`. Also performs sanity check and emits an event.
     */
    function _setRedeemPrincipalDelayTimestamp(uint256 newValue) internal {
        require(newValue <= MAX_REDEEM_DELAY_DURATION_TIME, "USR012");
        require(newValue > redeemDelayTimestamp, "USR019");
        emit RedeemPrincipalDelayTimestampSet(
            redeemPrincipalDelayTimestamp,
            newValue
        );
        redeemPrincipalDelayTimestamp = newValue;
    }

    /**
     * @notice internal function for changing the value of `whitelistEnabled`.
     */
    function _setWhitelistEnabled(bool newValue) internal {
        emit WhitelistEnabledSet(whitelistEnabled, newValue);
        whitelistEnabled = newValue;
    }

    /**
     * @notice internal function for changing the value of `redeemManageRate`.
     */
    function _setRedeemManageRate(uint256 newValue) internal {
        emit RedeemManageRateSet(redeemManageRate, newValue);
        redeemManageRate = newValue;
    }

    /**
     * @notice internal function used in both of the overloaded `claimDelayedRedeems` functions
     */
    function _claimDelayedRedeems(
        address recipient,
        uint256 maxNumberOfDelayedRedeemsToClaim
    ) internal {
        uint256 delayedRedeemsCompletedBefore = _userRedeems[recipient]
            .delayedRedeemsCompleted;
        uint256 numToClaim = 0;
        DebtTokenAmount[] memory debtAmounts;
        (numToClaim, debtAmounts) = _getDebtTokenAmount(
            recipient,
            delayedRedeemsCompletedBefore,
            redeemDelayTimestamp,
            maxNumberOfDelayedRedeemsToClaim
        );

        if (numToClaim > 0) {
            // mark the i delayedRedeems as claimed
            _userRedeems[recipient].delayedRedeemsCompleted =
                delayedRedeemsCompletedBefore +
                numToClaim;

            // transfer the delayedRedeems to the recipient
            uint256 burn_amount = 0;
            bytes memory data;
            for (uint256 i = 0; i < debtAmounts.length; i++) {
                address token = debtAmounts[i].token;
                require(!pausedTokenlist[token], "SYS003");
                uint256 amountUniBTC = debtAmounts[i].amount;
                uint256 amountToSend = _amounts(token, amountUniBTC);
                tokenDebts[token].claimedAmount += amountUniBTC;
                burn_amount += amountUniBTC;
                if (token == NATIVE_BTC) {
                    // transfer native token to the recipient
                    IVault(vault).execute(address(this), "", amountToSend);
                    (bool success, ) = payable(recipient).call{value: amountToSend}("");
                    if (success == false) {
                        revert("USR010");
                    }
                } else {
                    data = abi.encodeWithSelector(
                        IERC20.transfer.selector,
                        recipient,
                        amountToSend
                    );
                    // transfer erc20 token to the recipient
                    IVault(vault).execute(token, data, 0);
                }
                emit DelayedRedeemsClaimed(recipient, token, amountToSend);
            }

            //burn claimed amount unibtc
            if (IERC20(uniBTC).allowance(address(this), vault) < burn_amount) {
                IERC20(uniBTC).safeApprove(vault, burn_amount);
            }
            data = abi.encodeWithSelector(
                IMintableContract.burnFrom.selector,
                address(this),
                burn_amount
            );
            IVault(vault).execute(uniBTC, data, 0);

            emit DelayedRedeemsCompleted(
                recipient,
                burn_amount,
                delayedRedeemsCompletedBefore + numToClaim
            );
        }
    }

    /**
     * @notice internal function used in both of the overloaded `claimPrincipals` functions
     */
    function _claimPrincipals(
        address recipient,
        uint256 maxNumberOfDelayedRedeemsToClaim
    ) internal {
        uint256 delayedRedeemsCompletedBefore = _userRedeems[recipient]
            .delayedRedeemsCompleted;
        uint256 numToClaim = 0;
        DebtTokenAmount[] memory debtAmounts;
        (numToClaim, debtAmounts) = _getDebtTokenAmount(
            recipient,
            delayedRedeemsCompletedBefore,
            redeemPrincipalDelayTimestamp,
            maxNumberOfDelayedRedeemsToClaim
        );

        if (numToClaim > 0) {
            // mark the i delayedRedeems as claimed
            _userRedeems[recipient].delayedRedeemsCompleted =
                delayedRedeemsCompletedBefore +
                numToClaim;

            uint256 amountToSend = 0;
            for (uint256 i = 0; i < debtAmounts.length; i++) {
                address token = debtAmounts[i].token;
                uint256 amountUniBTC = debtAmounts[i].amount;
                tokenDebts[token].claimedAmount += amountUniBTC;
                amountToSend += amountUniBTC;
                emit DelayedRedeemsPrincipalClaimed(
                    recipient,
                    token,
                    amountUniBTC
                );
            }
            IERC20(uniBTC).safeTransfer(recipient, amountToSend);
            emit DelayedRedeemsPrincipalCompleted(
                recipient,
                amountToSend,
                delayedRedeemsCompletedBefore + numToClaim
            );
        }
    }

    /**
     * @notice internal function to rebase the base quota and timestamp for the specific btc token.
     */
    function _rebase(address token) internal {
        uint256 quota = _getQuota(token);
        baseQuotas[token] = quota;
        lastRebaseTimestamps[token] = block.timestamp;
    }

    /**
     * @dev determine the valid wrapped and native BTC amount.
     * @param token a specific btc token
     * @param amount the redeem amount of the uniBTC token
     * return the valid amount of the delayedRedeem btc token
     */
    function _amounts(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        if (token == NATIVE_BTC) {
            return (amount * EXCHANGE_RATE_BASE);
        }
        uint8 decs = ERC20(token).decimals();
        if (decs == 8) return (amount);
        if (decs == 18) {
            return (amount * EXCHANGE_RATE_BASE);
        }
        return (0);
    }

    /**
     * @dev get accumulative redeem quota for different btc token
     * @param token the specific btc token
     */
    function _getQuota(address token) internal view returns (uint256) {
        uint256 quota = baseQuotas[token] +
            (block.timestamp - lastRebaseTimestamps[token]) * numTokensPerSecond[token];
        uint256 maxFreeQuota = tokenDebts[token].totalAmount + maxFreeQuotas[token];
        if (quota <= maxFreeQuota) {
            return (quota);
        }
        return (maxFreeQuota);
    }

    /**
     * @dev get the claimable debt list from _userRedeems through delayTimestamp
     * @param recipient the account had created the delayedRedeem
     * @param delayedRedeemsCompletedBefore the number of delayedRedeems that have been completed
     * @param delayTimestamp the delay time for claiming a delayedRedeem
     * @param maxNumberOfDelayedRedeemsToClaim used to limit the maximum number of delayedRedeems to loop through claiming.
     * return the number of delayedRedeems that can be claimed and the DebtTokenAmount array(record the debt btc token and amount)
     */
    function _getDebtTokenAmount(
        address recipient,
        uint256 delayedRedeemsCompletedBefore,
        uint256 delayTimestamp,
        uint256 maxNumberOfDelayedRedeemsToClaim
    ) internal view returns (uint256, DebtTokenAmount[] memory) {
        uint256 _userRedeemsLength = _userRedeems[recipient]
            .delayedRedeems
            .length;
        uint256 numToClaim = 0;
        while (
            numToClaim < maxNumberOfDelayedRedeemsToClaim &&
            (delayedRedeemsCompletedBefore + numToClaim) < _userRedeemsLength
        ) {
            // copy delayedRedeem from storage to memory
            DelayedRedeem memory delayedRedeem = _userRedeems[recipient]
                .delayedRedeems[delayedRedeemsCompletedBefore + numToClaim];

            // check if delayedRedeem can be claimed. break the loop as soon as a delayedRedeem cannot be claimed
            if (
                block.timestamp <
                delayedRedeem.timestampCreated + delayTimestamp
            ) {
                break;
            }

            // increment i to account for the delayedRedeem being claimed
            unchecked {
                ++numToClaim;
            }
        }

        if (numToClaim > 0) {
            DebtTokenAmount[] memory debtAmounts = new DebtTokenAmount[](
                numToClaim
            );
            uint256 tokenCount = 0;
            for (uint256 i = 0; i < numToClaim; i++) {
                DelayedRedeem memory delayedRedeem = _userRedeems[recipient]
                    .delayedRedeems[delayedRedeemsCompletedBefore + i];
                bool found = false;

                for (uint256 j = 0; j < tokenCount; j++) {
                    if (debtAmounts[j].token == delayedRedeem.token) {
                        debtAmounts[j].amount += delayedRedeem.amount;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    debtAmounts[tokenCount] = DebtTokenAmount({
                        token: delayedRedeem.token,
                        amount: delayedRedeem.amount
                    });
                    tokenCount++;
                }
            }

            // the token type count is equal to the number of the delayedRedeems length
            if (tokenCount == debtAmounts.length) {
                return (numToClaim, debtAmounts);
            }

            // some of the delayedRedeems have the same token type
            DebtTokenAmount[] memory finalAmounts = new DebtTokenAmount[](
                tokenCount
            );
            for (uint256 k = 0; k < tokenCount; k++) {
                finalAmounts[k] = debtAmounts[k];
            }
            return (numToClaim, finalAmounts);
        }

        return (0, new DebtTokenAmount[](0));
    }

    /**
     * ======================================================================================
     *
     * EVENTS
     *
     * ======================================================================================
     */

    /**
     * @notice event for delayedRedeem creation
     */
    event DelayedRedeemCreated(
        address recipient,
        address token,
        uint256 amount,
        uint256 index,
        uint256 rate
    );

    /**
     * @notice event for the claiming of delayedRedeems
     */
    event DelayedRedeemsClaimed(
        address recipient,
        address token,
        uint256 amountClaimed
    );

    /**
     * @notice event for the claiming principal of delayedRedeems
     */
    event DelayedRedeemsPrincipalClaimed(
        address recipient,
        address token,
        uint256 amountClaimed
    );

    /**
     * @notice event for the claiming of delayedRedeems
     */
    event DelayedRedeemsCompleted(
        address recipient,
        uint256 amountBurned,
        uint256 delayedRedeemsCompleted
    );

    /**
     * @notice event for the claiming principal of delayedRedeems
     */
    event DelayedRedeemsPrincipalCompleted(
        address recipient,
        uint256 amountPrincipal,
        uint256 delayedRedeemsCompleted
    );

    /**
     * @notice Emitted when the `redeemDelayTimestamp` variable is modified from `previousValue` to `newValue`.
     */
    event RedeemDelayTimestampSet(uint256 previousValue, uint256 newValue);

    /**
     * @notice Emitted when the `redeemPrincipalDelayTimestamp` variable is modified from `previousValue` to `newValue`.
     */
    event RedeemPrincipalDelayTimestampSet(
        uint256 previousValue,
        uint256 newValue
    );

    /**
     * @notice event for adding tokens in btclist
     */
    event BtclistAdded(address[] tokens);

    /**
     * @notice event for removing tokens from btclist
     */
    event BtclistRemoved(address[] tokens);

    /**
     * @notice event for adding accounts in whitelist
     */
    event WhitelistAdded(address[] accounts);

    /**
     * @notice event for removing accounts from whitelist
     */
    event WhitelistRemoved(address[] accounts);

    /**
     * @notice event for setting the whitelistEnabled
     */
    event WhitelistEnabledSet(bool previousValue, bool newValue);

    /**
     * @notice event for adding accounts in blacklist
     */
    event BlacklistAdded(address[] accounts);

    /**
     * @notice event for removing accounts from blacklist
     */
    event BlacklistRemoved(address[] accounts);

    /**
     * @notice event for setting the max free quota
     */
    event MaxFreeQuotasSet(
        address token,
        uint256 previousValue,
        uint256 newValue
    );

    /**
     * @notice event for setting the redeem btc token amount per second
     */
    event NumTokensPerSecondSet(
        address token,
        uint256 previousValue,
        uint256 newValue
    );

    /**
     * @notice event for adding accounts in pausedTokenlist
     */
    event PausedTokenlistAdded(address[] tokens);

    /**
     * @notice event for removing accounts from pausedTokenlist
     */
    event PausedTokenlistRemoved(address[] tokens);

    /**
     * @notice event for setting the redeem manage rate
     */
    event RedeemManageRateSet(uint256 previousValue, uint256 newValue);

    /**
     * @notice event for withdrawing the manage fee
     */
    event ManageFeeWithdrawn(address recipient, uint256 amount);
}
