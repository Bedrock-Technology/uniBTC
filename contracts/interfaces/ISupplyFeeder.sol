// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ISupplyFeeder {
    /**
     * @dev Calculate the current total native token assets supplied for the Vault but locked outside the Vault for
     * DeFi profit yield.
     */
    function lockedSupply() external view returns(uint256);

    /**
     * @dev Calculate the current total wrapped token assets supplied for the Vault but locked outside the Vault for
     * DeFi profit yield
     */
    function lockedSupply(address token) external view returns(uint256);
}