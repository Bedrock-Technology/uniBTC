// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

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

interface ILockNativeTokenWithBridgeFee {
    event LockNativeTokenWithBridgeFee(
        address account,
        uint256 amount,
        string destBtcAddr,
        uint256 bridgeFee
    );
}