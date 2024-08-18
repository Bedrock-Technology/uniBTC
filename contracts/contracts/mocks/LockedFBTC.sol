// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Reference: https://github.com/fbtc-com/fbtcX-contract/blob/main/src/LockedFBTC.sol
contract LockedFBTC is Initializable, ERC20Upgradeable, PausableUpgradeable, AccessControlUpgradeable {
    enum Operation {
        Nop, // starts from 1.
        Mint,
        Burn,
        CrosschainRequest,
        CrosschainConfirm
    }

    enum Status {
        Unused,
        Pending,
        Confirmed,
        Rejected
    }

    struct Request {
        Operation op;
        Status status;
        uint128 nonce; // Those can be packed into one slot in evm storage.
        bytes32 srcChain;
        bytes srcAddress;
        bytes32 dstChain;
        bytes dstAddress;
        uint256 amount; // Transfer value without fee.
        uint256 fee;
        bytes extra;
    }

    // constants
    uint256 public constant fee = 1e8;

    // event

    /// @notice Event emitted when lockedFBTC is minted.
    /// @param minter Address of the account performing the minting.
    /// @param receivedAmount Amount of lockedFBTC received.
    /// @param fee Fee deducted from the minting process.
    event MintLockedFbtcRequest(address indexed minter, uint256 receivedAmount, uint256 fee);

    /// @notice Event emitted when initiating a mint FBTC and burn lockedFBTC request.
    /// @param owner Address of the account requesting the redemption.
    /// @param depositTx Transaction hash of the deposit.
    /// @param outputIndex Index of the output in the transaction.
    /// @param amount Amount of FBTC to be redeemed.
    event RedeemFbtcRequest(address indexed owner, bytes32 depositTx, uint256 outputIndex, uint256 amount);

    /// @notice Event emitted when confirming mint FBTC and burn lockedFBTC request.
    /// @param owner Address of the account whose redemption was confirmed.
    /// @param amount Amount of FBTC redeemed.
    event ConfirmRedeemFbtc(address indexed owner, uint256 amount);

    // Roles

    /// @notice Role hash for pausers, capable of pausing the contract.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Role hash for minters, capable of minting new locked FBTC.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // State variables

    /// @notice The ERC20 token interface for FBTC.
    IERC20Upgradeable public fbtc;

    /// @dev Disables initializer function of the inherited contract.
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with necessary parameters and roles.
    function initialize(
        address _fbtc,
        address _admin,
        address _pauser,
        address _minter
    ) public initializer {

        require(_admin != address(0), "Admin cannot be zero Address");
        require(_fbtc != address(0), "Admin cannot be zero Address");

        __ERC20_init("Bedrock LockedFBTC", "Bedrock_LockedFBTC");
        __Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _pauser);
        _grantRole(MINTER_ROLE, _minter);

        fbtc = IERC20Upgradeable(_fbtc);
    }

    /// @notice Returns the decimals used by the BTC, overridden to 8.
    function decimals() public pure override returns (uint8) {
        return 8;
    }

    /// @notice Pauses all functions except the emergency burn method.
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses all functions.
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // Minter methods

     /// @notice Mints lockedFBTC tokens in response to a burn FBTC request on the FBTC bridge.
     /// @dev This function mints lockedFBTC tokens to the caller's address after transferring the equivalent amount of FBTC tokens to this contract.
     /// @param _amount The amount of lockedFBTC to be minted.
     /// @return realAmount The actual amount of lockedFBTC minted after deducting the burn fee.
    function mintLockedFbtcRequest(uint256 _amount)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
        returns (uint256 realAmount)
    {
        require(_amount > 0, "Amount must be greater than zero.");
        require(fbtc.balanceOf(msg.sender) >= _amount, "Insufficient FBTC balance.");

        SafeERC20Upgradeable.safeTransferFrom(fbtc, msg.sender, address(this), _amount);

        realAmount = _amount - fee;
        require(realAmount > 0, "Real amount must be greater than zero after fee deduction.");
        _mint(msg.sender, realAmount);

        emit MintLockedFbtcRequest(msg.sender, realAmount, fee);
    }

     /// @notice Initiates a request to redeem FBTC tokens by submitting a corresponding BTC deposit transaction.
     /// @dev This function triggers a new mint request on the FBTC bridge using the BTC deposit transaction details.
     /// @param _amount The amount of FBTC to redeem.
     /// @param _depositTxid The BTC deposit txid
     /// @param _outputIndex The transaction output index to user's deposit address.
     /// @return _hash The created hash of the mint request.
     /// @return _r The request details stored in the FBTC bridge.
    function redeemFbtcRequest(uint256 _amount, bytes32 _depositTxid, uint256 _outputIndex)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
        returns (bytes32 _hash, Request memory _r)
    {
        require(_amount > 0, "Amount should be greater than 0.");
        require(_amount <= totalSupply(), "Amount out of limit.");

        emit RedeemFbtcRequest(msg.sender, _depositTxid, _outputIndex, _amount);
    }

     /// @notice Confirms the redemption of lockedFBTC tokens and completes the transfer to the token holder.
     /// @dev Burns the lockedFBTC tokens and transfers the equivalent FBTC from this contract to the caller.
     /// @param _amount The amount of FBTC to confirm and transfer.
    function confirmRedeemFbtc(uint256 _amount) public onlyRole(MINTER_ROLE) whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero.");
        require(fbtc.balanceOf(address(this)) >= _amount, "Insufficient FBTC balance in contract.");

        _burn(msg.sender, _amount);
        SafeERC20Upgradeable.safeTransfer(fbtc, msg.sender, _amount);

        emit ConfirmRedeemFbtc(msg.sender, _amount);
    }

    /// @notice Allows minters to burn their locked FBTC.
    function burn(uint256 _amount) public onlyRole(MINTER_ROLE) whenNotPaused {
        _burn(msg.sender, _amount);
    }
}
