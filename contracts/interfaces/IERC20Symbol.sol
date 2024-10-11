// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Interface for ERC20 symbol
interface IERC20Symbol {
    function symbol() external view returns (string memory);
}