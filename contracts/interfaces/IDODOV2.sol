// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Reference: https://etherscan.io/address/0xa356867fDCEa8e71AEaF87805808803806231FdC
//https://github.com/DODOEX/dodo-example/blob/main/solidity/contracts/DODOProxyIntegrate.sol
interface IDODOV2ProxyV2 {
    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

    function _DODO_APPROVE_PROXY_() external view returns (address);
}

// Reference: https://etherscan.io/address/0xD39DFbfBA9E7eccd813918FfbDa10B783EA3b3C6
interface IDODOV2Pool {
    function _BASE_TOKEN_() external view returns (IERC20);
}

// Reference: https://etherscan.io/address/0x335aC99bb3E51BDbF22025f092Ebc1Cf2c5cC619
interface IDODOAppProxy {
    function _DODO_APPROVE_() external view returns (address);
}
