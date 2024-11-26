// SPDX-License-Identifier: MIT

pragma solidity >=0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol";
import {uniBTC} from "../contracts/mocks/uniBTC.sol";

contract SetOFTAdapter is Script {
    function run() external {}

    function setMinter() external {
        // Get the current chain name based on the chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);
        // Construct paths to the configuration and local pool JSON files
        string memory localPoolPath =
            string.concat(vm.projectRoot(), "/script/output/deployedOFTAdapter_", chainName, ".json");
        // Extract addresses from the JSON files
        address oftAdapterAddress =
            HelperUtils.getAddressFromJson(vm, localPoolPath, string.concat(".deployedOFTAdapter_", chainName));

        HelperUtils.NetworkConfig memory networkConfig = HelperUtils.getNetworkConfig(block.chainid);

        address owner = vm.envAddress("OWNER_ADDRESS");
        vm.startBroadcast(owner);
        uniBTC btc = uniBTC(networkConfig.uniBTC);
        btc.grantRole(btc.MINTER_ROLE(), oftAdapterAddress);
        vm.stopBroadcast();
        console.log("set %s, uniBTC:", chainName, networkConfig.uniBTC);
        console.log("role address:", oftAdapterAddress);
    }

    function mint() external {
        // Get the current chain name based on the chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);
        HelperUtils.NetworkConfig memory networkConfig = HelperUtils.getNetworkConfig(block.chainid);
        address owner = vm.envAddress("OWNER_ADDRESS");
        vm.startBroadcast(owner);
        uniBTC btc = uniBTC(networkConfig.uniBTC);
        btc.mint(owner, 10e8);
        vm.stopBroadcast();
        console.log("set %s, uniBTC:", chainName, networkConfig.uniBTC);
        console.log("mint 10BTC on:", owner);
        console.log("%s balance:", owner, btc.balanceOf(owner));
    }
}
