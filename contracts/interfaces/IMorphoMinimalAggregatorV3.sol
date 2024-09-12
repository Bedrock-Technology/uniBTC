// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


// Reference: https://github.com/morpho-org/morpho-blue-oracles/blob/main/src/wsteth-exchange-rate-adapter/interfaces/MinimalAggregatorV3Interface.sol
interface IMorphoMinimalAggregatorV3 {
    function decimals() external view returns (uint8);
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}