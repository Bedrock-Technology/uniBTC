// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../interfaces/IUniBTCRate.sol";
import "../../interfaces/IMorphoMinimalAggregatorV3.sol";

// Reference: https://github.com/morpho-org/morpho-blue-oracles/blob/main/src/wsteth-exchange-rate-adapter/WstEthStEthExchangeRateChainlinkAdapter.sol
contract uniBTCRawBTCExchangeRateChainlinkAdapter is IMorphoMinimalAggregatorV3 {
    uint8 public constant decimals = 8;

    string public constant description = "uniBTC/RawBTC exchange rate";

    address public immutable uniBTCRate;

    constructor(address _uniBTCRate) {
        uniBTCRate = _uniBTCRate;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, int256(IUniBTCRate(uniBTCRate).getRate()), 0, 0, 0);
    }
}
