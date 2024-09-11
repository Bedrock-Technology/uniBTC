// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IUniBTCRate {
    function getRate() external pure returns (uint256);
}
