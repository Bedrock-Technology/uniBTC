// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {TokenPool} from "@chainlink/contracts-ccip/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/RateLimiter.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol"; // Utility functions for JSON parsing and chain info
import {HelperConfig} from "./HelperConfig.s.sol"; // Network configuration helper

contract UpdateRateLimiters is Script {
    function run() public {}

    function updateRL(uint256 _remoteChainId, RateLimiter.Config memory _outbound, RateLimiter.Config memory _inbound)
        public
    {
        vm.startBroadcast(vm.envAddress("OWNER_ADDRESS"));

        // Get the current chain name based on the chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);
        // Construct paths to the configuration and local pool JSON files
        string memory localPoolPath =
            string.concat(vm.projectRoot(), "/script/output/deployedTokenPool_", chainName, ".json");
        address poolAddress =
            HelperUtils.getAddressFromJson(vm, localPoolPath, string.concat(".deployedTokenPool_", chainName));
        // Instantiate the TokenPool contract
        TokenPool poolContract = TokenPool(poolAddress);
        // Fetch the remote network configuration to get the chain selector
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory remoteNetworkConfig =
            HelperUtils.getNetworkConfig(helperConfig, _remoteChainId);

        // Update the rate limiter configurations
        poolContract.setChainRateLimiterConfig(remoteNetworkConfig.chainSelector, _outbound, _inbound);

        vm.stopBroadcast();
    }
}
