// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol"; // Utility functions for JSON parsing and chain info
import {HelperConfig} from "./HelperConfig.s.sol"; // Network configuration helper
import {TokenPool} from "@chainlink/contracts-ccip/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/RateLimiter.sol";

contract ApplyChainUpdates is Script {
    function run() public {}

    function applyChain(
        uint256 _remoteChainId,
        bool _allowed,
        RateLimiter.Config memory _outbound,
        RateLimiter.Config memory _inbound
    ) external {
        // Get the current chain name based on the chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);

        // Construct paths to the configuration and local pool JSON files
        string memory localPoolPath =
            string.concat(vm.projectRoot(), "/script/output/deployedTokenPool_", chainName, ".json");

        // Get the remote chain name based on the remoteChainId
        string memory remoteChainName = HelperUtils.getChainName(_remoteChainId);
        string memory remotePoolPath =
            string.concat(vm.projectRoot(), "/script/output/deployedTokenPool_", remoteChainName, ".json");

        // Extract addresses from the JSON files
        address poolAddress =
            HelperUtils.getAddressFromJson(vm, localPoolPath, string.concat(".deployedTokenPool_", chainName));
        address remotePoolAddress =
            HelperUtils.getAddressFromJson(vm, remotePoolPath, string.concat(".deployedTokenPool_", remoteChainName));
        // Fetch the remote network configuration to get the chain selector
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory remoteNetworkConfig =
            HelperUtils.getNetworkConfig(helperConfig, _remoteChainId);

        require(poolAddress != address(0), "Invalid pool address");
        require(remotePoolAddress != address(0), "Invalid remote pool address");
        require(remoteNetworkConfig.tokenAddress != address(0), "Invalid remote token address");
        require(remoteNetworkConfig.chainSelector != 0, "chainSelector is not defined for the remote chain");

        vm.startBroadcast(vm.envAddress("OWNER_ADDRESS"));

        // Instantiate the local TokenPool contract
        TokenPool poolContract = TokenPool(poolAddress);
        console.log("pool's owner:%s", poolContract.owner());

        // Prepare chain update data for configuring cross-chain transfers
        TokenPool.ChainUpdate[] memory chainUpdates = new TokenPool.ChainUpdate[](1);

        chainUpdates[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteNetworkConfig.chainSelector, // Chain selector of the remote chain
            allowed: _allowed, // Enable transfers to the remote chain
            remotePoolAddress: abi.encode(remotePoolAddress), // Encoded address of the remote pool
            remoteTokenAddress: abi.encode(remoteNetworkConfig.tokenAddress), // Encoded address of the remote token
            outboundRateLimiterConfig: _outbound,
            inboundRateLimiterConfig: _inbound
        });

        // Apply the chain updates to configure the pool
        poolContract.applyChainUpdates(chainUpdates);

        console.log("Chain %s update applied to pool at address:%s", chainName, poolAddress);

        vm.stopBroadcast();
    }
}
