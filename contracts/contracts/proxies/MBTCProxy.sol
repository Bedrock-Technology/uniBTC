// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/IVault.sol";
import "../../interfaces/IMTokenSwap.sol";
import "../../interfaces/IBTCLayer2Bridge.sol";

contract MBTCProxy is Ownable {
    address private constant EMPTY_TOKEN = address(0);
    uint256 private BASE_NONCE = uint256(keccak256("BEDROCK_MERLIN"));

    address public immutable vault;
    address public constant mBTC = 0xB880fd278198bd590252621d4CD071b1842E9Bcd;
    address public constant mTokenSwap = 0x72A817715f174a32303e8C33cDCd25E0dACfE60b;
    address public immutable btcLayer2Bridge;

    uint256 public nonce;

    constructor(address _vault, uint256 _nonce) {
        vault = _vault;
        nonce = _nonce;
        btcLayer2Bridge = IMTokenSwap(mTokenSwap).bridgeAddress();
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
     * @dev swap '_amount' Native-BTC on the Merlin network (layer 2) to '_amount - getBridgeFee()' BTC on the Bitcoin network (layer 1).
     */
    function swapL2BTCToL1BTC(uint256 _amount, string memory _destBtcAddr) external onlyOwner {
        bytes memory data;
        // Lock L2 native BTC of Vault contract with bridge fee on BTCLayer2Bridge contract.
        data = abi.encodeWithSelector(IBTCLayer2Bridge.lockNativeToken.selector, _destBtcAddr);
        IVault(vault).execute(btcLayer2Bridge, data, _amount);
    }

    /**
     * @dev get cross-chain bridge fee required to swap M-BTC to BTC
     */
    function getBridgeFee() public view returns (uint256) {
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
        txHash = bytes32(BASE_NONCE + nonce);
    }
}
