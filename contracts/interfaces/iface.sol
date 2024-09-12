// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IVault.sol";
import "./IMintable.sol";

interface ISGNFeeQuerier {
    function feeBase() external view returns (uint256);
    function feePerByte() external view returns (uint256);
}

// Reference: https://github.com/fbtc-com/fbtcX-contract/blob/main/src/LockedFBTC.sol
interface ILockedFBTC {
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

    function mintLockedFbtcRequest(uint256 _amount) external returns (uint256 realAmount);
    function redeemFbtcRequest(uint256 _amount, bytes32 _depositTxid, uint256 _outputIndex) external returns (bytes32 _hash, Request memory _r);
    function confirmRedeemFbtc(uint256 _amount) external;
    function burn(uint256 _amount) external;
    function fbtc() external returns (address);
}

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