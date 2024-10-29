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
     * @notice the duration time in 1 day (60 * 60 * 24 = 86,400)
     */
    uint256 public constant DAY_DELAY_DURATION_TIME = 86400;

    /**
     * @notice the maximum amount of unibtc that can be burned setting in a single day
     */
    uint256 public constant DAY_MAX_ALLOWED_CAP = 1000e8;

    /**
     * @notice Delay enforced by this contract for completing any delayedRedeem, Measured in timestamp,
     * and adjustable by this contract's owner,up to a maximum of `MAX_REDEEM_DELAY_DURATION_TIME`.
     * Minimum value is 0 (i.e. no delay enforced).
     */
    uint256 public redeemDelayTimestamp;

    /**
     * @notice The timestamp at which the redeem functionality was enabled for the first time.
     */
    uint256 public redeemStartedTimestamp;

    /**
     * @notice The address of the ERC20 uniBTC token.
     */
    address public uniBTC;

    /**
     * @notice The address of the Vault contract.
     */
    address public vault;

    /**
     * @notice struct used to pack data into a single storage slot
     */
    struct DelayedRedeem {
        uint224 amount;
        uint32 timestampCreated;
        address token;
    }

    /**
     * @notice struct used to store a single users delayedRedeem data
     */
    struct UserDelayedRedeems {
        uint256 delayedRedeemsCompleted;
        DelayedRedeem[] delayedRedeems;
    }

    /**
     * @notice define a structure for temporary storage of ERC20 tokens and corresponding cumulative amounts
     */
    struct DebtTokenAmount {
        address token;
        uint256 amount;
    }

    /**
     * @notice struct used to store the total amount of debt and the total amount of claimed debt for a specific token
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
     * @notice mapping to store the whitelist status of an address.
     * only whitelist address can redeem using unibtc
     */
    mapping(address => bool) private whitelist;

    /**
     * @notice mapping to store the wrapBtcList status of an address.
     * only wrapBtcList address(contain wrapped and native BTC) can redeem using unibtc
     */
    mapping(address => bool) private wrapBtcList;

    /**
     * @notice flag to enable/disable the whitelist feature.
     * If enabled, only whitelisted addresses can redeem using unibtc.
     */
    bool public whitelistEnabled;

    /**
     * @notice the total redeem cap for a single day
     */
    uint256 public dayCap;

    /**
     * @notice the total redeem cap for duration history day
     */
    uint256 private _totalCap;

    /**
     * @notice the last updated day for update the total redeem cap
     */
    uint256 public lastUpdatedDay;

    /**
     * @notice the total debt of all delayedRedeems
     */
    uint256 public totalDebt;

    /**
     * @notice the address of the native BTC token
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
     * @notice mapping to store the blacklist status of an address.
     * only not in blacklist address can redeem using unibtc
     */
    mapping(address => bool) private blacklist;

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
     * @notice admin-only function for modifying the value of the `redeemDelayTimestamp` variable.
     */
    function initialize(
        address _defaultAdmin,
        address _uniBTC,
        address _vault,
        uint256 _redeemDelayTimestamp,
        bool _whitelistEnabled,
        uint256 _dayCap
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        require(_defaultAdmin != address(0x0), "SYS001");
        require(_uniBTC != address(0x0), "SYS001");
        require(_vault != address(0x0), "SYS001");
        require(_dayCap <= DAY_MAX_ALLOWED_CAP, "USR013");

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(PAUSER_ROLE, _defaultAdmin);

        uniBTC = _uniBTC;
        vault = _vault;
        _totalCap = _dayCap;
        dayCap = _dayCap;
        redeemStartedTimestamp = block.timestamp;
        _setWhitelistEnabled(_whitelistEnabled);
        _setRedeemPrincipalDelayTimestamp(MAX_REDEEM_DELAY_DURATION_TIME);
        _setRedeemDelayTimestamp(_redeemDelayTimestamp);
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
     */
    function setRedeemDelayTimestamp(
        uint256 _newValue
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRedeemDelayTimestamp(_newValue);
    }

    /**
     * @dev add a new wrapped or native btc address in wrapBtcList for the contract
     */
    function addToWrapBtcList(
        address _token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        wrapBtcList[_token] = true;
        emit WrapBtcListAdded(_token);
    }

    /**
     * @dev remove an address from wrapBtcList for the contract
     */
    function removeFromWrapBtcList(
        address _token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        wrapBtcList[_token] = false;
        emit WrapBtcListRemoved(_token);
    }

    /**
     * @dev set the whitelistEnabled for the contract
     */
    function setWhitelistEnabled(
        bool _enabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setWhitelistEnabled(_enabled);
    }

    /**
     * @dev add a new address in whitelist for the contract
     */
    function addToWhitelist(
        address _address
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelist[_address] = true;
        emit WhitelistAdded(_address);
    }

    /**
     * @dev remove an address from whitelist for the contract
     */
    function removeFromWhitelist(
        address _address
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelist[_address] = false;
        emit WhitelistRemoved(_address);
    }

    /**
     * @dev set a new day Cap for the contract
     */
    function setDayCap(uint256 _newCap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDayCap(_newCap);
    }

    /**
     * @dev set a new delay principal redeem block timestamp for the contract
     */
    function setRedeemPrincipalDelayTimestamp(
        uint256 _newValue
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRedeemPrincipalDelayTimestamp(_newValue);
    }

    /**
     * @dev add a new address in blacklist for the contract
     */
    function addToBlacklist(
        address _address
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        blacklist[_address] = true;
        emit BlacklistAdded(_address);
    }

    /**
     * @dev remove an address from blacklist for the contract
     */
    function removeFromBlacklist(
        address _address
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        blacklist[_address] = false;
        emit BlacklistRemoved(_address);
    }

    /**
     * ======================================================================================
     *
     * EXTERNAL FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * @notice Creates a delayed redeem for `_amount` to the `recipient`.
     * @dev check the address is in whitelist or not
     */
    function createDelayedRedeem(
        address _token,
        uint256 _amount
    ) external nonReentrant whenNotPaused onlyWhitelisted {
        require(wrapBtcList[_token], "SYS003");
        _updateTotalCap();
        require(_totalCap >= _amount + totalDebt, "USR010");
        //lock unibtc in the contract
        IERC20(uniBTC).safeTransferFrom(msg.sender, address(this), _amount);
        uint224 RedeemAmount = uint224(_amount);
        if (RedeemAmount != 0) {
            DelayedRedeem memory delayedRedeem = DelayedRedeem({
                amount: RedeemAmount,
                timestampCreated: uint32(block.timestamp),
                token: _token
            });
            _userRedeems[msg.sender].delayedRedeems.push(delayedRedeem);

            tokenDebts[_token].totalAmount += _amount;
            totalDebt += _amount;

            emit DelayedRedeemCreated(
                msg.sender,
                _token,
                RedeemAmount,
                _userRedeems[msg.sender].delayedRedeems.length - 1
            );
        }
    }

    /**
     * @notice Called in order to claim delayed redeem made to msg.sender that have passed the `redeemDelayTimestamp` period.
     * @param maxNumberOfDelayedRedeemsToClaim Used to limit the maximum number of delayedRedeems to loop through claiming.
     * @dev that the caller of this function cannot control where the funds are sent, but they can control when the
     * funds are sent once the redeem becomes claimable and token comeback the contract.
     */
    function claimDelayedRedeems(
        uint256 maxNumberOfDelayedRedeemsToClaim
    ) external nonReentrant whenNotPaused onlyNotBlacklisted {
        _claimDelayedRedeems(msg.sender, maxNumberOfDelayedRedeemsToClaim);
    }

    /**
     * @notice Called in order to claim delayed redeem made to the caller that have passed the `redeemDelayTimestamp` period.
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
     * @notice Called in order to claim delayed redeem made to msg.sender that have passed the `redeemPrincipalDelayTimestamp` period.
     * @param maxNumberOfDelayedRedeemsToClaim Used to limit the maximum number of delayedRedeems to loop through claiming.
     * @dev that the caller of this function can control when the funds are sent once the principal becomes claimable.
     */
    function claimPrincipals(
        uint256 maxNumberOfDelayedRedeemsToClaim
    ) external nonReentrant whenNotPaused onlyNotBlacklisted {
        _claimPrincipals(msg.sender, maxNumberOfDelayedRedeemsToClaim);
    }

    /**
     * @notice Called in order to claim delayed redeem made to the caller that have passed the `redeemPrincipalDelayTimestamp` period.
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
     * @notice Getter function for the mapping `_userRedeems`
     */
    function userRedeems(
        address user
    ) external view returns (UserDelayedRedeems memory) {
        return _userRedeems[user];
    }

    /**
     * @notice Getter function for fetching the delayedRedeem at the `index`th entry from the `_userRedeems[user].delayedRedeems` array
     */
    function userDelayedRedeemByIndex(
        address user,
        uint256 index
    ) external view returns (DelayedRedeem memory) {
        return _userRedeems[user].delayedRedeems[index];
    }

    /**
     * @notice Getter function for fetching the length of the delayedRedeems array of a specific user
     */
    function userRedeemsLength(address user) external view returns (uint256) {
        return _userRedeems[user].delayedRedeems.length;
    }

    /**
     * @notice Convenience function for checking whether or not the delayedRedeem at the `index`th entry from
     * the `_userRedeems[user].delayedRedeems` array is currently claimable
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
     * @notice Convenience function for checking whether or not the delayedRedeem at the `index`th entry from
     * the `_userRedeems[user].delayedRedeems` array is currently principal claimable
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
     * @notice Getter function to get all delayedRedeems of the `user`
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
     * @notice Getter function to get all delayedRedeems that are currently claimable by the `user`
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
            // check if delayedRedeem can be claimed. break the loop as soon as a delayedRedeem cannot be claimed
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
     * @notice get current available Cap
     */
    function getAvailableCap() external view returns (uint256) {
        uint256 currentDay = (block.timestamp - redeemStartedTimestamp) /
            DAY_DELAY_DURATION_TIME;
        uint256 currentCap = _totalCap;
        if (currentDay > lastUpdatedDay) {
            uint256 passeddays = currentDay - lastUpdatedDay;
            currentCap = _totalCap + passeddays * dayCap;
        }
        return currentCap - totalDebt;
    }

    /**
     * @dev check the address is in whitelist or not
     */
    function isWhitelisted(address _address) external view returns (bool) {
        return whitelist[_address];
    }

    /*
     * @dev check the address is in wrap-btc list or not
     */
    function isWrapBtcListed(address _token) external view returns (bool) {
        return wrapBtcList[_token];
    }

    /**
     * @dev check the address is in blacklist or not
     */
    function isBlacklisted(address _address) external view returns (bool) {
        return blacklist[_address];
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
        emit redeemDelayTimestampSet(redeemDelayTimestamp, newValue);
        redeemDelayTimestamp = newValue;
    }

    /**
     * @notice internal function for changing the value of `redeemPrincipalDelayTimestamp`. Also performs sanity check and emits an event.
     */
    function _setRedeemPrincipalDelayTimestamp(uint256 newValue) internal {
        require(newValue <= MAX_REDEEM_DELAY_DURATION_TIME, "USR012");
        require(newValue > redeemDelayTimestamp, "USR019");
        emit redeemPrincipalDelayTimestampSet(
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
     * @notice internal function for changing the value of _totalCap.
     */
    function _updateTotalCap() internal {
        uint256 currentDay = (block.timestamp - redeemStartedTimestamp) /
            DAY_DELAY_DURATION_TIME;
        if (currentDay > lastUpdatedDay) {
            uint256 passeddays = currentDay - lastUpdatedDay;
            _totalCap = _totalCap + passeddays * dayCap;
            lastUpdatedDay = currentDay;
        }
    }

    /**
     * @notice internal function for changing the value of `dayCap`.
     */
    function _setDayCap(uint256 newCap) internal {
        require(newCap <= DAY_MAX_ALLOWED_CAP, "USR013");
        _updateTotalCap();
        emit DayCapSet(dayCap, newCap);
        dayCap = newCap;
    }

    /**
     * @dev determine the valid wrapped and native BTC amount.
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
     * @dev get the claimable debt list from _userRedeems through delayTimestamp
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

            if (tokenCount == debtAmounts.length) {
                return (numToClaim, debtAmounts);
            }

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
        uint256 index
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
    event redeemDelayTimestampSet(uint256 previousValue, uint256 newValue);

    /**
     * @notice Emitted when the `redeemPrincipalDelayTimestamp` variable is modified from `previousValue` to `newValue`.
     */
    event redeemPrincipalDelayTimestampSet(
        uint256 previousValue,
        uint256 newValue
    );

    /**
     * @notice event for adding a new address in wrapBtcList
     */
    event WrapBtcListAdded(address token);

    /**
     * @notice event for removing an address from wrapBtcList
     */
    event WrapBtcListRemoved(address token);

    /**
     * @notice event for setting the dayCap
     */
    event DayCapSet(uint256 previousValue, uint256 newValue);

    /**
     * @notice event for adding a new address in whitelist
     */
    event WhitelistAdded(address account);

    /**
     * @notice event for removing an address from whitelist
     */
    event WhitelistRemoved(address account);

    /**
     * @notice event for setting the whitelistEnabled
     */
    event WhitelistEnabledSet(bool previousValue, bool newValue);

    /**
     * @notice event for adding a new address in blacklist
     */
    event BlacklistAdded(address account);

    /**
     * @notice event for removing an address from blacklist
     */
    event BlacklistRemoved(address account);
}
