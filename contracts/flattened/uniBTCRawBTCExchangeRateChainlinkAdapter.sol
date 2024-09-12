// File: contracts/interfaces/IMorphoMinimalAggregatorV3.sol

// Reference: https://github.com/morpho-org/morpho-blue-oracles/blob/main/src/wsteth-exchange-rate-adapter/interfaces/MinimalAggregatorV3Interface.sol
interface IMorphoMinimalAggregatorV3 {
    function decimals() external view returns (uint8);
    function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
// File: contracts/interfaces/IUniBTCRate.sol

interface IUniBTCRate {
    function getRate() external pure returns (uint256);
}

// File: contracts/contracts/morpho/uniBTCRawBTCExchangeRateChainlinkAdapter.sol

// Reference: https://github.com/morpho-org/morpho-blue-oracles/blob/main/src/wsteth-exchange-rate-adapter/WstEthStEthExchangeRateChainlinkAdapter.sol
contract uniBTCRawBTCExchangeRateChainlinkAdapter is IMorphoMinimalAggregatorV3 {
    uint8 public constant decimals = 8;

    string public constant description = "uniBTC/BTC exchange rate";

    address public immutable uniBTCRate;

    constructor(address _uniBTCRate) {
        uniBTCRate = _uniBTCRate;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, int256(IUniBTCRate(uniBTCRate).getRate()), 0, 0, 0);
    }
}