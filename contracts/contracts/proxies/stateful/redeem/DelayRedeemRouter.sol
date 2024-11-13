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
     * @notice The duration of one day in seconds (60 * 60 * 24 = 86,400)
     */
    uint256 public constant SECONDS_IN_A_DAY = 86400;

    /**
     * @notice The duration time set to 30 days (60 * 60 * 24 * 30 = 2,592,000).
     */
    uint256 public constant MAX_REDEEM_DELAY_DURATION = 2592000;

    /**
     * @notice The maximum amount of uniBTC that can be burned in a single day for each specific BTC token.
     */
    uint256 public constant MAX_DAILY_REDEEM_CAP = 100e8;

    /**
     * @notice Defines the redeem fee rate range, with precision to ten-thousandths.
     */
    uint256 public constant REDEEM_FEE_RATE_RANGE = 10000;

    /**
     * @notice Default redeem fee rate (2%).
     */
    uint256 public constant DEFAULT_REDEEM_FEE_RATE = 200;

    /**
     * @notice Delay for completing any delayed redeem, measured in timestamps.
     * Adjustable by the contract owner, with a maximum limit of `MAX_REDEEM_DELAY_DURATION`.
     * The minimum value is 0 (i.e., no enforced delay).
     */
    uint256 public redeemDelayDuration;

    /**
     * @notice The address of the ERC20 uniBTC token.
     */
    address public uniBTC;

    /**
     * @notice The address of the Vault contract.
     */
    address public vault;

    /**
     * @notice Struct for storing delayed redeem information.
     * @param amount The amount of the delayed redeem for a specific BTC token.
     * @param timestampCreated The timestamp at which the `DelayedRedeem` was created.
     * @param token The address of a specific BTC token.
     */
    struct DelayedRedeem {
        uint224 amount;
        uint32 timestampCreated;
        address token;
    }

    /**
     * @notice Struct for storing a user's delayed redeem data.
     * @param delayedRedeemsCompleted The number of delayed redeems that have been completed.
     * @param delayedRedeems An array of delayed redeems.
     */
    struct UserDelayedRedeems {
        uint256 delayedRedeemsCompleted;
        DelayedRedeem[] delayedRedeems;
    }

    /**
     * @notice Struct for temporarily storing a debt BTC token type and corresponding cumulative amounts.
     * @param token The address of a specific BTC token.
     * @param amount The redeem amount of a specific BTC token.
     */
    struct DebtTokenAmount {
        address token;
        uint256 amount;
    }

    /**
     * @notice Struct for tracking the total and claimed debt amounts for a specific BTC token.
     * @param totalAmount The total debt amount for a specific BTC token.
     * @param claimedAmount The total claimed debt amount for a specific BTC token.
     */
    struct TokenDebtInfo {
        uint256 totalAmount;
        uint256 claimedAmount;
    }

    /**
     * @notice Mapping of user addresses to their delayed redeem information.
     * Internal, with an external getter function named `userRedeems`.
     */
    mapping(address => UserDelayedRedeems) internal _userRedeems;

    /**
     * @notice Mapping of token addresses to debt information for each btc token.
     */
    mapping(address => TokenDebtInfo) public tokenDebts;

    /**
     * @notice Mapping to store the whitelist status of accounts.
     * Only addresses in the whitelist can redeem using uniBTC.
     */
    mapping(address => bool) private whitelist;

    /**
     * @notice Mapping to store the status of specific BTC tokens.
     * Only tokens in the BTC list (wrapped or native BTC) can be redeemed using uniBTC.
     */
    mapping(address => bool) private btclist;

    /**
     * @notice Flag to enable or disable the whitelist feature.
     * If enabled, only whitelisted addresses can redeem using uniBTC.
     */
    bool public whitelistEnabled;

    /**
     * @notice The maximum free quota for tokens per redemption.
     */
    mapping(address => uint256) public maxFreeQuotas;

    /**
     * @notice The base redeem quota for different BTC tokens over a defined historical timestamp duration.
     */
    mapping(address => uint256) public baseQuotas;

    /**
     * @notice The redeem amount per second for each specific BTC token.
     */
    mapping(address => uint256) public numTokensPerSecond;

    /**
     * @notice Records the last rebase timestamp for each specific BTC token.
     */
    mapping(address => uint256) public lastRebaseTimestamps;

    /**
     * @notice Defines the native BTC token.
     */
    address public constant NATIVE_BTC =
        address(0xbeDFFfFfFFfFfFfFFfFfFFFFfFFfFFffffFFFFFF);

    /**
     * @notice Used for converting certain wrapped BTC tokens to 18 decimals.
     */
    uint256 public constant EXCHANGE_RATE_BASE = 1e10;

    /**
     * @notice Principal redemption period.
     */
    uint256 public redeemPrincipalDelayDuration;

    /**
     * @notice Mapping to store the blacklist status of accounts.
     * Only accounts not in the blacklist can redeem using uniBTC.
     */
    mapping(address => bool) private blacklist;

    /**
     * @notice Mapping to store the status of paused tokens.
     * Only tokens not in the pausedTokenList can be used for redemption or specific BTC token claims.
     */
    mapping(address => bool) private pausedTokenlist;

    /**
     * @notice Tracks the user redeem fee rate for the contract.
     */
    uint256 public redeemFeeRate;

    /**
     * @notice Tracks the redeem fee for the contract.
     */
    uint256 public managementFee;

    receive() external payable {}

    /**
     * ======================================================================================
     *
     * CONSTRUCTOR
     *
     * ======================================================================================
     */

    /**
     * @dev Disables the ability to call any additional initializer functions.
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
     * @dev Modifier to ensure the caller is whitelisted.
     */
    modifier onlyWhitelisted() {
        require(!whitelistEnabled || whitelist[msg.sender], "USR009");
        _;
    }

    /**
     * @dev Modifier to ensure the caller is not blacklisted.
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
     * @notice Initializes the contract with admin and token settings.
     * @param _defaultAdmin The default admin address (RBAC).
     * @param _uniBTC The address of the ERC20 uniBTC token.
     * @param _vault The address of the Bedrock Vault contract.
     * @param _redeemDelayDuration The delay time before claiming a delayed redeem.
     * @param _whitelistEnabled Enables or disables the whitelist feature.
     */
    function initialize(
        address _defaultAdmin,
        address _uniBTC,
        address _vault,
        uint256 _redeemDelayDuration,
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
        _setRedeemPrincipalDelayDuration(MAX_REDEEM_DELAY_DURATION);
        _setRedeemDelayDuration(_redeemDelayDuration);
        _setRedeemFeeRate(DEFAULT_REDEEM_FEE_RATE);
    }

    /**
     * @dev Pauses the contract.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Sets a new delay redeem duration.
     * @param _newDuration New delay time, after which users can claim the delayed redeem.
     */
    function setRedeemDelayDuration(
        uint256 _newDuration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRedeemDelayDuration(_newDuration);
    }

    /**
     * @dev Adds tokens to the BTC list for redeeming with uniBTC.
     * @param _tokens List of wrapped or native BTC tokens to be added.
     */
    function addTokensToBtclist(
        address[] calldata _tokens
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            btclist[_tokens[i]] = true;
        }
        emit BtclistAdded(_tokens);
    }

    /**
     * @dev Removes tokens from the BTC list for redeeming with uniBTC.
     * @param _tokens List of wrapped or native BTC tokens to be removed.
     */
    function removeTokensFromBtclist(
        address[] calldata _tokens
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            btclist[_tokens[i]] = false;
        }
        emit BtclistRemoved(_tokens);
    }

    /**
     * @dev Enables or disables the whitelist feature.
     * @param _enabled True if only whitelisted accounts can redeem with uniBTC.
     */
    function setWhitelistEnabled(
        bool _enabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setWhitelistEnabled(_enabled);
    }

    /**
     * @dev Adds accounts to the whitelist, allowing them to redeem with uniBTC.
     * @param _accounts List of accounts to be added to the whitelist.
     */
    function addAccountsToWhitelist(
        address[] calldata _accounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = true;
        }
        emit WhitelistAdded(_accounts);
    }

    /**
     * @dev Removes accounts from the whitelist, restricting their redemption access.
     * @param _accounts List of accounts to be removed from the whitelist.
     */
    function removeAccountsFromWhitelist(
        address[] calldata _accounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = false;
        }
        emit WhitelistRemoved(_accounts);
    }

    /**
     * @dev Adds accounts to the blacklist, preventing them from claiming delayed redeems.
     * @param _accounts List of accounts to be blacklisted.
     */
    function addAccountsToBlacklist(
        address[] calldata _accounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            blacklist[_accounts[i]] = true;
        }
        emit BlacklistAdded(_accounts);
    }

    /**
     * @dev Removes accounts from the blacklist, allowing them to claim delayed redeems.
     * @param _accounts List of accounts to be removed from the blacklist.
     */
    function removeAccountsFromBlacklist(
        address[] calldata _accounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            blacklist[_accounts[i]] = false;
        }
        emit BlacklistRemoved(_accounts);
    }

    /**
     * @dev Adds tokens to the paused token list, blocking them from being redeemed or claimed.
     * @param _tokens List of tokens to be paused.
     */
    function pauseTokens(
        address[] calldata _tokens
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            pausedTokenlist[_tokens[i]] = true;
        }
        emit PausedTokenlistAdded(_tokens);
    }

    /**
     * @dev Removes tokens from the paused token list, allowing them to be redeemed or claimed.
     * @param _tokens List of tokens to be resumed.
     */
    function unpauseTokens(
        address[] calldata _tokens
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            pausedTokenlist[_tokens[i]] = false;
        }
        emit PausedTokenlistRemoved(_tokens);
    }

    /**
     * @dev Sets the maximum free quota for each redeemable token type.
     * @param _tokens List of token addresses.
     * @param _quotas List of maximum free quotas for each token.
     */
    function setMaxFreeQuotasForTokens(
        address[] calldata _tokens,
        uint256[] calldata _quotas
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokens.length == _quotas.length, "SYS006");
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_quotas[i] < MAX_DAILY_REDEEM_CAP, "USR013");
            emit MaxFreeQuotasSet(
                _tokens[i],
                maxFreeQuotas[_tokens[i]],
                _quotas[i]
            );
            maxFreeQuotas[_tokens[i]] = _quotas[i];
        }
    }

    /**
     * @dev Withdraws the redeem management fee.
     * @param _amount Amount to withdraw.
     * @param _recipient Recipient address for the fee withdrawal.
     */
    function withdrawManagementFee(
        uint256 _amount,
        address _recipient
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount <= managementFee, "USR003");
        managementFee -= _amount;
        IERC20(uniBTC).safeTransfer(_recipient, _amount);
        emit ManagementFeeWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Sets the redeem amount per second for each specific BTC token.
     * @param _tokens List of BTC tokens.
     * @param _quotas List of redeem amounts per second for each BTC token.
     */
    function setRedeemQuotaPerSecond(
        address[] calldata _tokens,
        uint256[] calldata _quotas
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokens.length == _quotas.length, "SYS006");
        uint256 maxQuotaPerSecond = MAX_DAILY_REDEEM_CAP / SECONDS_IN_A_DAY;
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_quotas[i] <= maxQuotaPerSecond, "USR013");
            // this time need using old quota per second to rebase quota and timestamp
            _rebase(_tokens[i]);
            emit RedeemQuotaPerSecondSet(
                _tokens[i],
                numTokensPerSecond[_tokens[i]],
                _quotas[i]
            );
            numTokensPerSecond[_tokens[i]] = _quotas[i];
        }
    }

    /**
     * @dev Sets a new delay for principal redemption.
     * @param _newDuration New delay time after which users can claim the principal.
     */
    function setRedeemPrincipalDelayDuration(
        uint256 _newDuration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRedeemPrincipalDelayDuration(_newDuration);
    }

    /**
     * @dev Sets the redeem management rate for the contract.
     * @param _newFeeRate The new value for the redeem management rate,
     * which is used to calculate the redemption management fee.
     */
    function setRedeemFeeRate(
        uint256 _newFeeRate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRedeemFeeRate(_newFeeRate);
    }

    /**
     * ======================================================================================
     *
     * EXTERNAL FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * @notice Creates a delayed redemption request for the `amount` to `msg.sender`.
     * @dev Checks if the provided amount meets the redemption requirements for the user.
     * @param token The specific BTC token address.
     * @param amount The amount of BTC tokens to be redeemed with a delay.
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
            // user bill need to pay the redeem fee
            uint224 userRedeemAmount = uint224(
                (amount * (REDEEM_FEE_RATE_RANGE - redeemFeeRate)) /
                    REDEEM_FEE_RATE_RANGE
            );
            uint256 userRedeemFee = amount - userRedeemAmount;
            managementFee += userRedeemFee;

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
                userRedeemFee
            );
        }
    }

    /**
     * @notice Claims delayed redemptions that have passed the `redeemDelayDuration` period for `msg.sender`.
     * @dev The caller controls when funds are released to `msg.sender` once the redemption is claimable.
     * @param maxNumberOfDelayedRedeemsToClaim Limits the maximum number of delayed redemptions to claim in a loop.
     */
    function claimDelayedRedeems(
        uint256 maxNumberOfDelayedRedeemsToClaim
    ) external nonReentrant whenNotPaused onlyNotBlacklisted {
        _claimDelayedRedeems(msg.sender, maxNumberOfDelayedRedeemsToClaim);
    }

    /**
     * @notice Claims all delayed redemptions that have passed the `redeemDelayDuration` period for `msg.sender`.
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
     * @notice Claims delayed redemption principals that have passed the `redeemPrincipalDelayDuration` period.
     * @dev The caller controls when funds are released once the principal becomes claimable.
     * @param maxNumberOfDelayedRedeemsToClaim Limits the maximum number of delayed redemption principals to claim in a loop.
     */
    function claimPrincipals(
        uint256 maxNumberOfDelayedRedeemsToClaim
    ) external nonReentrant whenNotPaused onlyNotBlacklisted {
        _claimPrincipals(msg.sender, maxNumberOfDelayedRedeemsToClaim);
    }

    /**
     * @notice Claims all delayed redemption principals that have passed the `redeemPrincipalDelayDuration` period.
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
     * @notice Getter function for retrieving the delayed redemption records of a user.
     * @param user The account that created the delayed redemption.
     * @return The UserDelayedRedeems struct for the specified user.
     */
    function userRedeems(
        address user
    ) external view returns (UserDelayedRedeems memory) {
        return _userRedeems[user];
    }

    /**
     * @notice Getter function for retrieving a specific delayed redemption at the `index` position from the user's array.
     * @param user The account that created the delayed redemption.
     * @param index The index of the delayed redemption in the user's array.
     * @return The DelayedRedeem struct at the specified `index` position.
     */
    function userDelayedRedeemByIndex(
        address user,
        uint256 index
    ) external view returns (DelayedRedeem memory) {
        return _userRedeems[user].delayedRedeems[index];
    }

    /**
     * @notice Getter function for retrieving the length of the user's delayed redemption array.
     * @param user The account that created the delayed redemption.
     * @return The length of the user's delayed redemption array.
     */
    function userRedeemsLength(address user) external view returns (uint256) {
        return _userRedeems[user].delayedRedeems.length;
    }

    /**
     * @notice Checks if a delayed redemption at the specified `index` in the user's array is currently claimable.
     * @param user The account that created the delayed redemption.
     * @param index The index of the delayed redemption in the user's array.
     * @return True if the delayed redemption at the specified `index` is currently claimable, false otherwise.
     */
    function canClaimDelayedRedeem(
        address user,
        uint256 index
    ) external view returns (bool) {
        return ((index >= _userRedeems[user].delayedRedeemsCompleted) &&
            (block.timestamp >=
                _userRedeems[user].delayedRedeems[index].timestampCreated +
                    redeemDelayDuration));
    }

    /**
     * @notice Checks if the principal of a delayed redemption at the specified `index` in the user's array is claimable.
     * @param user The account that created the delayed redemption.
     * @param index The index of the delayed redemption in the user's array.
     * @return True if the principal of the delayed redemption at the specified `index` is claimable, false otherwise.
     */
    function canClaimDelayedRedeemPrincipal(
        address user,
        uint256 index
    ) external view returns (bool) {
        return ((redeemPrincipalDelayDuration > redeemDelayDuration &&
            index >= _userRedeems[user].delayedRedeemsCompleted) &&
            (block.timestamp >=
                _userRedeems[user].delayedRedeems[index].timestampCreated +
                    redeemPrincipalDelayDuration));
    }

    /**
     * @notice Getter function to retrieve all unclaimed delayed redemptions for a user.
     * @param user The account that created the delayed redemption.
     * @return An array of DelayedRedeem structs for all unclaimed delayed redemptions of the user.
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
     * @notice Getter function to retrieve all currently claimable delayed redemptions for a user.
     * @param user The account that created the delayed redemption.
     * @return An array of DelayedRedeem structs for all claimable delayed redemptions of the user.
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
                delayedRedeem.timestampCreated + redeemDelayDuration
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
     * @notice Retrieves the available redemption cap for a specific BTC token.
     * @param token The BTC token address for which to get the available redemption cap.
     * @return The available redemption cap for the specified token.
     */
    function getAvailableCap(address token) external view returns (uint256) {
        if (btclist[token]) {
            return (_getQuota(token) - tokenDebts[token].totalAmount);
        }
        return (0);
    }

    /**
     * @dev Checks if an account is in the whitelist.
     * @param account The address of the account to check.
     * @return True if the account is in the whitelist, false otherwise.
     */
    function isWhitelisted(address account) external view returns (bool) {
        return whitelist[account];
    }

    /**
     * @dev Checks if a specific BTC token is in the BTC list.
     * @param token The BTC token address to check.
     * @return True if the token is in the BTC list, false otherwise.
     */
    function isBtclisted(address token) external view returns (bool) {
        return btclist[token];
    }

    /**
     * @dev Checks if an account is in the blacklist.
     * @param account The address of the account to check.
     * @return True if the account is in the blacklist, false otherwise.
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
     * @notice Internal function to update `redeemDelayDuration`. Includes a sanity check and emits an event.
     * @param newDuration The new delayed time for the redemption delay.
     */
    function _setRedeemDelayDuration(uint256 newDuration) internal {
        require(newDuration <= MAX_REDEEM_DELAY_DURATION, "USR012");
        require(newDuration < redeemPrincipalDelayDuration, "USR019");
        emit RedeemDelayDurationSet(redeemDelayDuration, newDuration);
        redeemDelayDuration = newDuration;
    }

    /**
     * @notice Internal function to update `redeemPrincipalDelayDuration`. Includes a sanity check and emits an event.
     * @param newDuration The new delayed time for the redemption principal delay.
     */
    function _setRedeemPrincipalDelayDuration(uint256 newDuration) internal {
        require(newDuration <= MAX_REDEEM_DELAY_DURATION, "USR012");
        require(newDuration > redeemDelayDuration, "USR019");
        emit RedeemPrincipalDelayDurationSet(
            redeemPrincipalDelayDuration,
            newDuration
        );
        redeemPrincipalDelayDuration = newDuration;
    }

    /**
     * @notice Internal function to update `whitelistEnabled`.
     * @param enabled The new boolean value for whitelist status.
     */
    function _setWhitelistEnabled(bool enabled) internal {
        emit WhitelistEnabledSet(enabled);
        whitelistEnabled = enabled;
    }

    /**
     * @notice Internal function to update `redeemFeeRate`.
     * @param newFeeRate The new management rate for redemption.
     */
    function _setRedeemFeeRate(uint256 newFeeRate) internal {
        require(newFeeRate <= REDEEM_FEE_RATE_RANGE, "USR011");
        emit RedeemFeeRateSet(redeemFeeRate, newFeeRate);
        redeemFeeRate = newFeeRate;
    }

    /**
     * @notice Internal function used by both overloaded `claimDelayedRedeems` functions.
     * @param recipient The account to receive the claimed delayed redeems.
     * @param maxNumberOfDelayedRedeemsToClaim The maximum number of delayed redeems to claim in a single call.
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
            redeemDelayDuration,
            maxNumberOfDelayedRedeemsToClaim
        );

        if (numToClaim > 0) {
            // mark the i delayedRedeems as claimed
            _userRedeems[recipient].delayedRedeemsCompleted =
                delayedRedeemsCompletedBefore +
                numToClaim;

            // transfer the delayedRedeems to the recipient
            uint256 burnAmount = 0;
            bytes memory data;
            for (uint256 i = 0; i < debtAmounts.length; i++) {
                address token = debtAmounts[i].token;
                require(!pausedTokenlist[token], "SYS003");
                uint256 amountUniBTC = debtAmounts[i].amount;
                uint256 amountToSend = _amounts(token, amountUniBTC);
                tokenDebts[token].claimedAmount += amountUniBTC;
                burnAmount += amountUniBTC;
                if (token == NATIVE_BTC) {
                    // transfer native token to the recipient
                    IVault(vault).execute(address(this), "", amountToSend);
                    (bool success, ) = payable(recipient).call{
                        value: amountToSend
                    }("");
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
            if (IERC20(uniBTC).allowance(address(this), vault) < burnAmount) {
                IERC20(uniBTC).safeApprove(vault, burnAmount);
            }
            data = abi.encodeWithSelector(
                IMintableContract.burnFrom.selector,
                address(this),
                burnAmount
            );
            IVault(vault).execute(uniBTC, data, 0);

            emit DelayedRedeemsCompleted(
                recipient,
                burnAmount,
                delayedRedeemsCompletedBefore + numToClaim
            );
        }
    }

    /**
     * @notice Internal function used by both overloaded `claimPrincipals` functions.
     * @param recipient The account to receive the claimed principals.
     * @param maxNumberOfDelayedRedeemsToClaim The maximum number of delayed redeems to claim in a single call.
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
            redeemPrincipalDelayDuration,
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
     * @notice Internal function to reset the base quota and timestamp for a specific BTC token.
     * @param token The BTC token address for which to rebase.
     */
    function _rebase(address token) internal {
        uint256 quota = _getQuota(token);
        baseQuotas[token] = quota;
        lastRebaseTimestamps[token] = block.timestamp;
    }

    /**
     * @dev Calculates the valid amount of wrapped or native BTC for a specified token.
     * @param token The specific BTC token.
     * @param amount The redemption amount in uniBTC.
     * @return The valid delayed redemption amount in BTC.
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
     * @dev Retrieves the cumulative redemption quota for a specific BTC token.
     * @param token The specific BTC token.
     */
    function _getQuota(address token) internal view returns (uint256) {
        uint256 quota = baseQuotas[token] +
            (block.timestamp - lastRebaseTimestamps[token]) *
            numTokensPerSecond[token];
        uint256 maxFreeQuota = tokenDebts[token].totalAmount +
            maxFreeQuotas[token];
        if (quota <= maxFreeQuota) {
            return (quota);
        }
        return (maxFreeQuota);
    }

    /**
     * @dev Retrieves the list of claimable debts from _userRedeems based on the delay timestamp.
     * @param recipient The account that created the delayed redemption.
     * @param delayedRedeemsCompletedBefore The number of delayed redemptions that have already been completed.
     * @param delayTimestamp The delay time for claiming a delayed redemption.
     * @param maxNumberOfDelayedRedeemsToClaim The maximum number of delayed redemptions to loop through for claiming.
     * @return The number of delayed redemptions that can be claimed, and an array of DebtTokenAmount records that include the debt token and the associated amount.
     */
    function _getDebtTokenAmount(
        address recipient,
        uint256 delayedRedeemsCompletedBefore,
        uint256 delayTimestamp,
        uint256 maxNumberOfDelayedRedeemsToClaim
    ) internal view returns (uint256, DebtTokenAmount[] memory) {
        uint256 redeemsLength = _userRedeems[recipient]
            .delayedRedeems
            .length;
        uint256 numToClaim = 0;
        while (
            numToClaim < maxNumberOfDelayedRedeemsToClaim &&
            (delayedRedeemsCompletedBefore + numToClaim) < redeemsLength
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
     * @notice Event emitted when a delayedRedeem is created.
     */
    event DelayedRedeemCreated(
        address recipient,
        address token,
        uint256 amount,
        uint256 index,
        uint256 redeemFee
    );

    /**
     * @notice Event emitted when delayedRedeems are claimed.
     */
    event DelayedRedeemsClaimed(
        address recipient,
        address token,
        uint256 amountClaimed
    );

    /**
     * @notice Event emitted when the principal of delayedRedeems is claimed.
     */
    event DelayedRedeemsPrincipalClaimed(
        address recipient,
        address token,
        uint256 amountClaimed
    );

    /**
     * @notice Event emitted when delayedRedeems are completed.
     */
    event DelayedRedeemsCompleted(
        address recipient,
        uint256 amountBurned,
        uint256 delayedRedeemsCompleted
    );

    /**
     * @notice Event emitted when the principal of delayedRedeems is completed.
     */
    event DelayedRedeemsPrincipalCompleted(
        address recipient,
        uint256 amountPrincipal,
        uint256 delayedRedeemsCompleted
    );

    /**
     * @notice Event emitted when the `redeemDelayDuration` variable is modified.
     */
    event RedeemDelayDurationSet(uint256 previousDuration, uint256 newDuration);

    /**
     * @notice Event emitted when the `redeemPrincipalDelayDuration` variable is modified.
     */
    event RedeemPrincipalDelayDurationSet(
        uint256 previousDuration,
        uint256 newDuration
    );

    /**
     * @notice Event emitted when tokens are added to the BTC list.
     */
    event BtclistAdded(address[] tokens);

    /**
     * @notice Event emitted when tokens are removed from the BTC list.
     */
    event BtclistRemoved(address[] tokens);

    /**
     * @notice Event emitted when accounts are added to the whitelist.
     */
    event WhitelistAdded(address[] accounts);

    /**
     * @notice Event emitted when accounts are removed from the whitelist.
     */
    event WhitelistRemoved(address[] accounts);

    /**
     * @notice Event emitted when the whitelistEnabled flag is set.
     */
    event WhitelistEnabledSet(bool enabled);

    /**
     * @notice Event emitted when accounts are added to the blacklist.
     */
    event BlacklistAdded(address[] accounts);

    /**
     * @notice Event emitted when accounts are removed from the blacklist.
     */
    event BlacklistRemoved(address[] accounts);

    /**
     * @notice Event emitted when the maximum free quota is set.
     */
    event MaxFreeQuotasSet(
        address token,
        uint256 previousQuota,
        uint256 newQuota
    );

    /**
     * @notice Event emitted when the number of redeemable BTC tokens per second is set.
     */
    event RedeemQuotaPerSecondSet(
        address token,
        uint256 previousQuota,
        uint256 newQuota
    );

    /**
     * @notice Event emitted when tokens are added to the paused token list.
     */
    event PausedTokenlistAdded(address[] tokens);

    /**
     * @notice Event emitted when tokens are removed from the paused token list.
     */
    event PausedTokenlistRemoved(address[] tokens);

    /**
     * @notice Event emitted when the redeem fee rate is set.
     */
    event RedeemFeeRateSet(uint256 previousFeeRate, uint256 newFeeRate);

    /**
     * @notice Event emitted when the management fee is withdrawn.
     */
    event ManagementFeeWithdrawn(address recipient, uint256 amount);
}
