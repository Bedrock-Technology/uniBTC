// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

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