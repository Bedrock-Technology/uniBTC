// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableContract is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

interface ISGNFeeQuerier {
    function feeBase() external view returns (uint256);
    function feePerByte() external view returns (uint256);
}

interface IVault {
    function execute(address target, bytes memory data, uint256 value) external returns(bytes memory);
    function adminWithdraw(uint256 _amount, address _target) external;
    function adminWithdraw(address _token, uint256 _amount, address _target) external;
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