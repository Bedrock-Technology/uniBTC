// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../../interfaces/iface.sol";


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
    function initialize(address _defaultAdmin, address _vault) initializer public {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        vault = _vault;
        nonce = uint256(keccak256("BEDROCK_BITLAYER"));
    }

    receive() external payable {}

    function stake(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount > 0, "amount needs bigger than 0");
        require(_amount <= vault.balance, "amount exceeds vault's balance");
        nonce += 1;
        IVault(vault).execute(address(this), "", _amount);
        emit TokenStaked(nonce, address(this), _amount, NATIVE_TOKEN, 0, 0, "");
    }

    function unStake(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount > 0, "amount needs bigger than 0");
        require(_amount + withdrawPendingAmount <= address(this).balance, "amount exceeds staked balance");
        nonce += 1;
        withdrawPendingAmount += _amount;
        withdrawPendingQueue[nonce] = _amount;
        emit UnboundRequired(nonce, address(this), _amount, NATIVE_TOKEN, "");
    }

    function approveUnbound(uint256[] memory reqIds) external onlyRole(BITLAYER_ROLE) {
        for (uint256 i = 0; i < reqIds.length; i++) {
            _approveUnbound(reqIds[i]);
        }
    }
    //TODO if we can delete this function
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
        // not found, do nothing.
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
    event TokenStaked(uint256 indexed reqId, address indexed user, uint256 indexed amount, address token,
        uint256 planId, uint256 duration, bytes extraInfo);
    event UnboundRequired(uint256 indexed reqId, address indexed user, uint256 indexed amount, address token,
        bytes extraInfo);
    event UnboundApproved(uint256 indexed reqId, bytes extraInfo);
}
