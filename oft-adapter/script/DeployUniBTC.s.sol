// SPDX-License-Identifier: MIT

pragma solidity >=0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {uniBTC} from "../contracts/mocks/uniBTC.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployUniBTC is Script {
    function run() external {
        address owner = vm.envAddress("OWNER_ADDRESS");

        vm.startBroadcast(vm.envAddress("DEPLOYER_ADDRESS"));
        //deploy proxyAdmin
        ProxyAdmin adminInstance = new ProxyAdmin(owner);
        uniBTC implementation = new uniBTC();
        TransparentUpgradeableProxy uniBTCProxy = new TransparentUpgradeableProxy(
            address(implementation), address(adminInstance), abi.encodeCall(implementation.initialize, (owner, owner))
        );
        vm.stopBroadcast();

        console.log("uniBTC Proxy address:", address(uniBTCProxy));
    }
}
