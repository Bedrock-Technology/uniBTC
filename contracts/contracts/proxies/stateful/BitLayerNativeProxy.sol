// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../../../interfaces/IVault.sol";

contract BitLayerNativeProxy is Initializable, AccessControlUpgradeable {
    address private constant NATIVE_TOKEN = address(0);
    uint256 private nonce;
    address public vault;
    bytes32 public constant BITLAYER_ROLE = keccak256("BITLAYER_ROLE");
    uint256 public withdrawPendingAmount;
    mapping(uint256 => uint256) public withdrawPendingQueue;

    constructor() {
        _disableInitializers();
    }

    /**
     * ======================================================================================
     *
     * ADMIN
     *
     * ======================================================================================
     */
    function initialize(address _defaultAdmin, address _vault) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        vault = _vault;
        nonce = uint256(keccak256("BEDROCK_BITLAYER"));
    }

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is sent to the contract without any data.
    receive() external payable {}

    /// @param _amount amount of stake
    function stake(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount > 0, "USR014");
        require(_amount <= vault.balance, "USR015");
        nonce += 1;
        IVault(vault).execute(address(this), "", _amount);
        emit TokenStaked(nonce, address(this), _amount, NATIVE_TOKEN, 0, 0, "");
    }

    /// @param _amount amount of unstake
    function unstake(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount > 0, "USR014");
        require(_amount + withdrawPendingAmount <= address(this).balance, "USR015");
        nonce += 1;
        withdrawPendingAmount += _amount;
        withdrawPendingQueue[nonce] = _amount;
        emit UnboundRequired(nonce, address(this), _amount, NATIVE_TOKEN, "");
    }

    /// @param reqIds requestids that were approved to unbond
    function approveUnbound(uint256[] memory reqIds) external onlyRole(BITLAYER_ROLE) {
        for (uint256 i = 0; i < reqIds.length; i++) {
            _approveUnbound(reqIds[i]);
        }
    }

    /// @param planId planId to withdraw, not used currently
    function approveWithdraw(uint256 planId) external onlyRole(BITLAYER_ROLE) {}

    /**
     * ======================================================================================
     *
     * INTERNAL
     *
     * ======================================================================================
     */
    function _approveUnbound(uint256 reqId) internal {
        uint256 amount = withdrawPendingQueue[reqId];
        if (amount > 0) {
            withdrawPendingAmount -= amount;
            delete withdrawPendingQueue[reqId];
            payable(vault).transfer(amount);
        }
        emit UnboundApproved(reqId, "");
    }

    /**
     * ======================================================================================
     *
     * EVENTS
     *
     * ======================================================================================
     */
    event TokenStaked(
        uint256 indexed reqId,
        address indexed user,
        uint256 indexed amount,
        address token,
        uint256 planId,
        uint256 duration,
        bytes extraInfo
    );
    event UnboundRequired(
        uint256 indexed reqId, address indexed user, uint256 indexed amount, address token, bytes extraInfo
    );
    event UnboundApproved(uint256 indexed reqId, bytes extraInfo);
}
