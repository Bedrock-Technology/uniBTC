// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../interfaces/IUniBTCRate.sol";

contract uniBTCRate is IUniBTCRate {
    /**
     * @dev Function to get the rate, returning 1e8 (100,000,000)
     */
    function getRate() public pure returns (uint256) {
        return 1e8;
    }
}