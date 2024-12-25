// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
//forge script fscripts/deploy_proxyAdmin.s.sol --rpc-url $RPC_ETH_SEPOLIA --account $DEPLOYER --broadcast --verify --verifier-url $RPC_ETH_SEPOLIA_SCAN --etherscan-api-key $KEY_ETH_SEPOLIA_SCAN --delay 30

contract Depoly is Script {
    function run() external {
        address owner = vm.envAddress("OWNER_ADDRESS");

        vm.startBroadcast(vm.envAddress("DEPLOYER_ADDRESS"));
        ProxyAdmin adminInstance = new ProxyAdmin();
        adminInstance.transferOwnership(owner);
        vm.stopBroadcast();

        console.log("ProxyAdmin address:", address(adminInstance));
    }
}
