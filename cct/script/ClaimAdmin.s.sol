// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol"; // Utility functions for JSON parsing and chain info
import {HelperConfig} from "./HelperConfig.s.sol"; // Network configuration helper
import {TokenAdminRegistry} from "@chainlink/contracts-ccip/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";

contract ClaimAdmin is Script {
    function run() external {
        // Get the chain name based on the current chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);

        // Fetch the network configuration
        HelperConfig helperConfig = new HelperConfig();
        (,,, address tokenAdminRegistry,, address tokenAddress) = helperConfig.activeNetworkConfig();

        require(tokenAddress != address(0), "Invalid token address");
        require(tokenAdminRegistry != address(0), "Registry module owner custom is not defined for this network");

        address owner = vm.envAddress("OWNER_ADDRESS");

        vm.startBroadcast();
        TokenAdminRegistry(tokenAdminRegistry).proposeAdministrator(tokenAddress, owner);
        vm.stopBroadcast();
        console.log("chain:%s set proposeAdministrator to %s", chainName, owner);
    }
}
