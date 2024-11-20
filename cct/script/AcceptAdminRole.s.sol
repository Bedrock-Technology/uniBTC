// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol"; // Utility functions for JSON parsing and chain info
import {HelperConfig} from "./HelperConfig.s.sol"; // Network configuration helper
import {TokenAdminRegistry} from "@chainlink/contracts-ccip/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";

contract AcceptAdminRole is Script {
    function run() external {
        // Get the chain name based on the current chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);

        // Fetch the network configuration to get the TokenAdminRegistry address
        HelperConfig helperConfig = new HelperConfig();
        (,,, address tokenAdminRegistry,, address tokenAddress) = helperConfig.activeNetworkConfig();

        // Ensure the token address and TokenAdminRegistry address are valid
        require(tokenAddress != address(0), "Invalid token address");
        require(tokenAdminRegistry != address(0), "TokenAdminRegistry is not defined for this network");

        vm.startBroadcast(vm.envAddress("OWNER_ADDRESS"));

        // Get the address of the signer (the account executing the script)
        address signer = msg.sender;

        // Instantiate the TokenAdminRegistry contract
        TokenAdminRegistry tokenAdminRegistryContract = TokenAdminRegistry(tokenAdminRegistry);

        // Fetch the token configuration for the given token address
        TokenAdminRegistry.TokenConfig memory tokenConfig = tokenAdminRegistryContract.getTokenConfig(tokenAddress);

        // Get the pending administrator for the token
        address pendingAdministrator = tokenConfig.pendingAdministrator;

        // Ensure the signer is the pending administrator
        require(pendingAdministrator == signer, "Only the pending administrator can accept the admin role");

        // Accept the admin role for the token
        tokenAdminRegistryContract.acceptAdminRole(tokenAddress);

        console.log("Accepted admin role chain: %s, for token:", chainName, tokenAddress);

        vm.stopBroadcast();
    }
}
