// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// References:
//    1. https://scan.merlinchain.io/address/0x28AD6b7dfD79153659cb44C2155cf7C0e1CeEccC
//    2. https://github.com/MerlinLayer2/BTCLayer2BridgeContract/blob/main/contracts/BTCLayer2Bridge.sol
interface IBTCLayer2Bridge {
    event UnlockNativeToken(    // Emitted by the unlockNativeToken function (which is called by the MTokenSwap.swapMBtc function).
        bytes32 txHash,
        address account,
        uint256 amount
    );

    event LockNativeTokenWithBridgeFee( // Emitted by lockNativeToken function.
        address account,
        uint256 amount,
        string destBtcAddr,
        uint256 bridgeFee
    );

    function lockNativeToken(string memory destBtcAddr) external payable;
    function getBridgeFee(address msgSender, address token) external view returns(uint256);
}