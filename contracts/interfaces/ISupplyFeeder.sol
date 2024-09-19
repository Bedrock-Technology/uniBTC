// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ISupplyFeeder {
    /**
     * @dev Calculate the current total supply of assets for 'token'.
     */
    function totalSupply(address token) external view returns(uint256);
}