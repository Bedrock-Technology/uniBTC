// SPDX-License-Identifier: MIT

pragma solidity >=0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {uniBTCOFTAdapter} from "../contracts/uniBTCOFTAdapter.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol";

contract DeployUniBTC is Script {
    function run() external {
        HelperUtils.NetworkConfig memory networkConfig = HelperUtils.getNetworkConfig(block.chainid);
        address owner = vm.envAddress("OWNER_ADDRESS");
        string memory chainName = HelperUtils.getChainName(block.chainid);

        vm.startBroadcast(vm.envAddress("DEPLOYER_ADDRESS"));
        uniBTCOFTAdapter oftAdapter = new uniBTCOFTAdapter(networkConfig.uniBTC, networkConfig.endPoint, owner);
        vm.stopBroadcast();

        console.log("uniBTC OftAdapter address:", address(oftAdapter));

        // Serialize and write the token pool address to a new JSON file
        string memory jsonObj = "internal_key";
        string memory key = string(abi.encodePacked("deployedOFTAdapter_", chainName));
        string memory finalJson = vm.serializeAddress(jsonObj, key, address(oftAdapter));

        string memory poolFileName = string(abi.encodePacked("./script/output/deployedOFTAdapter_", chainName, ".json"));
        console.log("Writing deployed token pool address to file:", poolFileName);
        vm.writeJson(finalJson, poolFileName);
    }
}
