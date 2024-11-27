// SPDX-License-Identifier: MIT

pragma solidity >=0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {uniBTCOFTAdapter} from "../contracts/uniBTCOFTAdapter.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol";

contract SetOFTAdapter is Script {
    function run() external {}

    function setPeer(uint256 _chainid) external {
        // Get the current chain name based on the chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);
        string memory peerChainName = HelperUtils.getChainName(_chainid);
        // Construct paths to the configuration and local pool JSON files
        string memory localPoolPath =
            string.concat(vm.projectRoot(), "/script/output/deployedOFTAdapter_", chainName, ".json");
        // Extract addresses from the JSON files
        address oftAdapterAddress =
            HelperUtils.getAddressFromJson(vm, localPoolPath, string.concat(".deployedOFTAdapter_", chainName));
        string memory peerPoolPath =
            string.concat(vm.projectRoot(), "/script/output/deployedOFTAdapter_", peerChainName, ".json");
        // Extract addresses from the JSON files
        address peerOftAdapterAddress =
            HelperUtils.getAddressFromJson(vm, peerPoolPath, string.concat(".deployedOFTAdapter_", peerChainName));

        HelperUtils.NetworkConfig memory peerNetworkConfig = HelperUtils.getNetworkConfig(_chainid);

        address owner = vm.envAddress("OWNER_ADDRESS");
        vm.startBroadcast(owner);
        uniBTCOFTAdapter oftAdapter = uniBTCOFTAdapter(oftAdapterAddress);
        oftAdapter.setPeer(peerNetworkConfig.eid, bytes32(uint256(uint160(peerOftAdapterAddress))));
        vm.stopBroadcast();
        console.log("set %s, oftAdapterAddress:", chainName, oftAdapterAddress);
        console.log("peer %s, oftAdapterAddress:", peerChainName, peerOftAdapterAddress);
        console.log("peer eid:", peerNetworkConfig.eid);
    }
    //https://docs.layerzero.network/v2/developers/evm/protocol-gas-settings/default-config#custom-configuration
}
