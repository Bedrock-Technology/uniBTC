// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISGNFeeQuerier {
    function feeBase() external view returns (uint256);
    function feePerByte() external view returns (uint256);
}