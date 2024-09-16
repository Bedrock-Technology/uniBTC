// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IVault {
    function mint(address token, uint256 amount) external;
    function uniBTC() external returns (address);
}