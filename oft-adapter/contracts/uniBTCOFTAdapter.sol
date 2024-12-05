// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {OFTCore} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IMintableContract is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract uniBTCOFTAdapter is OFTCore {
    error AddressNotInWhitelist(address account);

    IMintableContract internal immutable innerToken;
    /// @notice Mapping to store the whitelist status of accounts.
    mapping(address => bool) public whitelist;
    /// @notice WhiteList enabled or not.
    bool public whitelistEnabled;

    modifier onlyInWhiteList(address _account) {
        if (whitelistEnabled) {
            if (!whitelist[_account]) {
                revert AddressNotInWhitelist(_account);
            }
        }
        _;
    }

    /// Event emitted when accounts added to whiteList.
    /// @param accounts The addresses added to whiteList.
    event WhitelistAdded(address[] accounts);

    /// Event emitted when accounts removed from whiteList.
    /// @param accounts The addresses removed from whiteList.
    event WhitelistRemoved(address[] accounts);

    /// Event emitted when whiteListEnabled seted.
    /// @param enabled Enable or Disable whiteList mechanism.
    event WhitelistEnabledSet(bool enabled);

    /// @dev constructor params
    /// @param _token ERC20 token address, uniBTC address
    /// @param _lzEndpoint Endpoint address, https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts
    /// @param _delegate Granting this address the ability to handle critical tasks such as setting configurations
    constructor(address _token, address _lzEndpoint, address _delegate, bool _whiteListEnabled)
        OFTCore(IERC20Metadata(_token).decimals(), _lzEndpoint, _delegate)
        Ownable(_delegate)
    {
        innerToken = IMintableContract(_token);
        whitelistEnabled = _whiteListEnabled;
    }

    /**
     * @dev Retrieves the address of the underlying ERC20 implementation.
     * @return The address of the adapted ERC-20 token.
     *
     * @dev In the case of OFTAdapter, address(this) and erc20 are NOT the same contract.
     */
    function token() public view returns (address) {
        return address(innerToken);
    }

    /**
     * @notice Indicates whether the OFT contract requires approval of the 'token()' to send.
     * @return requiresApproval Needs approval of the underlying token implementation.
     *
     * @dev In the case of default OFTAdapter, approval is required.
     * @dev In non-default OFTAdapter contracts with something like mint and burn privileges, it would NOT need approval.
     */
    function approvalRequired() external pure virtual returns (bool) {
        return true;
    }

    function setWhitelistEnabled(bool _enabled) external onlyOwner {
        whitelistEnabled = _enabled;
        emit WhitelistEnabledSet(_enabled);
    }

    function addToWhitelist(address[] calldata _accounts) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = true;
        }
        emit WhitelistAdded(_accounts);
    }

    /**
     * @dev Removes accounts from the whitelist, restricting their redemption access.
     * @param _accounts List of accounts to be removed from the whitelist.
     */
    function removeFromWhitelist(address[] calldata _accounts) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = false;
        }
        emit WhitelistRemoved(_accounts);
    }
    /**
     * @dev Burns tokens from the sender's specified balance.
     * @param _from The address to debit the tokens from.
     * @param _amountLD The amount of tokens to send in local decimals.
     * @param _minAmountLD The minimum amount to send in local decimals.
     * @param _dstEid The destination chain ID.
     * @return amountSentLD The amount sent in local decimals.
     * @return amountReceivedLD The amount received in local decimals on the remote.
     * @dev WARNING: The default OFTAdapter implementation assumes LOSSLESS transfers, ie. 1 token in, 1 token out.
     * IF the 'innerToken' applies something like a transfer fee, the default will NOT work...
     * a pre/post balance check will need to be done to calculate the amountReceivedLD.
     */

    function _debit(address _from, uint256 _amountLD, uint256 _minAmountLD, uint32 _dstEid)
        internal
        virtual
        override
        onlyInWhiteList(_from)
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);
        // @dev Burns tokens from the caller.
        innerToken.burnFrom(_from, amountSentLD);
    }

    /**
     * @dev Credits tokens to the specified address.
     * @param _to The address to credit the tokens to.
     * @param _amountLD The amount of tokens to credit in local decimals.
     * @dev _srcEid The source chain ID.
     * @return amountReceivedLD The amount of tokens ACTUALLY received in local decimals.
     *
     * @dev WARNING: The default OFTAdapter implementation assumes LOSSLESS transfers, ie. 1 token in, 1 token out.
     * IF the 'innerToken' applies something like a transfer fee, the default will NOT work...
     * a pre/post balance check will need to be done to calculate the amountReceivedLD.
     */
    function _credit(address _to, uint256 _amountLD, uint32 /*_srcEid*/ )
        internal
        virtual
        override
        onlyInWhiteList(_to)
        returns (uint256 amountReceivedLD)
    {
        // @dev Mints the tokens and transfers to the recipient.
        innerToken.mint(_to, _amountLD);
        // @dev In the case of NON-default OFTAdapter, the amountLD MIGHT not be == amountReceivedLD.
        return _amountLD;
    }
}
