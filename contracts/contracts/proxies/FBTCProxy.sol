// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/IVault.sol";
import "../../interfaces/ILockedFBTC.sol";

// Reference: https://github.com/fbtc-com/fbtcX-contract/blob/main/src/LockedFBTC.sol
contract FBTCProxy is AccessControl {
    address public immutable vault;
    address public immutable lockedFBTC;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(address _vault, address _lockedFBTC, address _admin) {
        vault = _vault;
        lockedFBTC = _lockedFBTC;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(OPERATOR_ROLE, _admin);
    }

    receive() external payable {
    revert("value only accepted by the Vault contract");
    }

    /**
     * @dev  mint lockedFBTC in response to a burn FBTC request on the FBTC bridge.
     */
    function mintLockedFbtcRequest(uint256 _amount) external onlyRole(OPERATOR_ROLE) {
        address fbtc = ILockedFBTC(lockedFBTC).fbtc();
        if (IERC20(fbtc).allowance(vault, lockedFBTC) < _amount) {
            bytes memory data = abi.encodeWithSelector(IERC20.approve.selector, lockedFBTC, _amount);
            IVault(vault).execute(fbtc, data, 0);
        }

        bytes memory data = abi.encodeWithSelector(ILockedFBTC.mintLockedFbtcRequest.selector, _amount);
        IVault(vault).execute(lockedFBTC, data, 0);
    }

    /**
     * @dev initiate a FBTC redemption request on the FBTC bridge with the corresponding BTC deposit tx details.
     */
    function redeemFbtcRequest(uint256 _amount, bytes32 _depositTxid, uint256 _outputIndex) external onlyRole(OPERATOR_ROLE) {
        bytes memory data = abi.encodeWithSelector(ILockedFBTC.redeemFbtcRequest.selector, _amount, _depositTxid, _outputIndex);
        IVault(vault).execute(lockedFBTC, data, 0);
    }

    /**
     * @dev burn Vault's locked FBTC and transfer back the equivalent FBTC to Vault.
     */
    function confirmRedeemFbtc(uint256 _amount) external onlyRole(OPERATOR_ROLE) {
        bytes memory data = abi.encodeWithSelector(ILockedFBTC.confirmRedeemFbtc.selector, _amount);
        IVault(vault).execute(lockedFBTC, data, 0);
    }
}
