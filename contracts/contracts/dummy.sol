// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract _DUMMY is ITransparentUpgradeableProxy {
    function admin() external view returns (address){return address(0);}

    function implementation() external view returns (address){return address(0);}

    function changeAdmin(address) external{}

    function upgradeTo(address) external{}

    function upgradeToAndCall(address, bytes memory) external payable{}
}
