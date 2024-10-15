// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Reference: https://etherscan.io/address/0x99a58482BD75cbab83b27EC03CA68fF489b5788f
interface ICurveFiRouter {
    function exchange(
        address[11] calldata _route,
        uint256[5][5] calldata _swap_params,
        uint256 _amount,
        uint256 _min_dy,
        address[5] calldata _pools,
        address _receiver
    ) external payable returns (uint256 amountOut);
}

//Reference: https://etherscan.io/address/0x839d6bDeDFF886404A6d7a788ef241e4e28F4802
interface ICurvePool {
    function fee() external view returns (uint256);
    function N_COINS() external view returns (uint256);
    function coins(uint256 index) external view returns (address);
}
