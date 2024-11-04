// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol"; // Utility functions for JSON parsing and chain info
import {HelperConfig} from "./HelperConfig.s.sol"; // Network configuration helper
import {BurnMintTokenPool} from "@chainlink/contracts-ccip/src/v0.8/ccip/pools/BurnMintTokenPool.sol";
import {BurnMintERC677} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";
import {IBurnMintERC20} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";

contract DeployBurnMintTokenPool is Script {
    function run() external {
        // Get the chain name based on the current chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);

        // Fetch network configuration (router and RMN proxy addresses)
        HelperConfig helperConfig = new HelperConfig();
        (, address router, address rmnProxy,,, address tokenAddress) = helperConfig.activeNetworkConfig();

        // Ensure that the token address, router, and RMN proxy are valid
        require(tokenAddress != address(0), "Invalid token address");
        require(router != address(0) && rmnProxy != address(0), "Router or RMN Proxy not defined for this network");

        // Cast the token address to the IBurnMintERC20 interface
        IBurnMintERC20 token = IBurnMintERC20(tokenAddress);

        vm.startBroadcast(vm.envAddress("DEPLOYER_ADDRESS"));

        // Deploy the BurnMintTokenPool contract associated with the token
        BurnMintTokenPool tokenPool = new BurnMintTokenPool(
            token,
            new address[](0), // Empty array for initial operators
            rmnProxy,
            router
        );

        console.log("Burn & Mint token pool deployed to:", address(tokenPool));

        vm.stopBroadcast();

        // Serialize and write the token pool address to a new JSON file
        string memory jsonObj = "internal_key";
        string memory key = string(abi.encodePacked("deployedTokenPool_", chainName));
        string memory finalJson = vm.serializeAddress(jsonObj, key, address(tokenPool));

        string memory poolFileName = string(abi.encodePacked("./script/output/deployedTokenPool_", chainName, ".json"));
        console.log("Writing deployed token pool address to file:", poolFileName);
        vm.writeJson(finalJson, poolFileName);
    }
}
