// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {uniBTC} from "../contracts/uniBTC.sol";
//forge script fscripts/deploy_uniBTC.s.sol --sig 'run(address)' '0xAb3630cEf046e2dFAFd327eB8b7B96D627dEFa83' --rpc-url $RPC_ETH_SEPOLIA --account $DEPLOYER --broadcast --verify --verifier-url $RPC_ETH_SEPOLIA_SCAN --etherscan-api-key $KEY_ETH_SEPOLIA_SCAN --delay 30

contract Depoly is Script {
    function run(address proxyAdmin) external {
        address owner = vm.envAddress("OWNER_ADDRESS");

        vm.startBroadcast(vm.envAddress("DEPLOYER_ADDRESS"));
        uniBTC implementation = new uniBTC();
        address[] memory freeze = new address[](0);
        TransparentUpgradeableProxy uniBTCProxy = new TransparentUpgradeableProxy(
            address(implementation), proxyAdmin, abi.encodeCall(implementation.initialize, (owner, owner, freeze))
        );
        vm.stopBroadcast();

        console.log("uniBTC Proxy address:", address(uniBTCProxy));
    }
}
