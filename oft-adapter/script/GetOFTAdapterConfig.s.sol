// SPDX-License-Identifier: MIT

pragma solidity >=0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol";
import {uniBTCOFTAdapter} from "../contracts/uniBTCOFTAdapter.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

contract GetOFTAdapter is Script {
    function run() external {}

    function getWhitelist(address[] memory _addresses) external view {
        string memory chainName = HelperUtils.getNetworkConfig(block.chainid).chainName;
        string memory localPoolPath =
            string.concat(vm.projectRoot(), "/script/output/deployedOFTAdapter_", chainName, ".json");
        address oftAdapterAddress =
            HelperUtils.getAddressFromJson(vm, localPoolPath, string.concat(".deployedOFTAdapter_", chainName));
        console.log("current:", chainName);
        uniBTCOFTAdapter adapter = uniBTCOFTAdapter(oftAdapterAddress);
        console.log("whitelistEnable:", adapter.whitelistEnabled());
        for (uint256 index = 0; index < _addresses.length; index++) {
            console.log("address: %s, ", _addresses[index], adapter.whitelist(_addresses[index]));
        }
    }

    function getConfig() external view {
        // Get the current chain name based on the chain ID
        string memory chainName = HelperUtils.getNetworkConfig(block.chainid).chainName;
        // Construct paths to the configuration and local pool JSON files
        string memory localPoolPath =
            string.concat(vm.projectRoot(), "/script/output/deployedOFTAdapter_", chainName, ".json");
        // Extract addresses from the JSON files
        address oftAdapterAddress =
            HelperUtils.getAddressFromJson(vm, localPoolPath, string.concat(".deployedOFTAdapter_", chainName));

        HelperUtils.NetworkConfig memory networkConfig = HelperUtils.getNetworkConfig(block.chainid);

        ILayerZeroEndpointV2 endPoint = ILayerZeroEndpointV2(networkConfig.endPoint);
        uniBTCOFTAdapter adapter = uniBTCOFTAdapter(oftAdapterAddress);
        console.log("current:", chainName);
        console.log("owner:", adapter.owner());
        for (uint256 index = 0; index < HelperUtils.getAllEids().length; index++) {
            if (adapter.peers(HelperUtils.getAllEids()[index]) != bytes32(0x0)) {
                HelperUtils.NetworkConfig memory peerNetworkConfig =
                    HelperUtils.getNetworkConfig(HelperUtils.getAllEids()[index]);
                string memory peerChainName = peerNetworkConfig.chainName;
                // get send executor
                bytes memory sendExecutorBytes =
                    endPoint.getConfig(oftAdapterAddress, networkConfig.sendUln302, peerNetworkConfig.eid, 1);
                HelperUtils.ExecutorConfig memory sendExecutorConfig =
                    abi.decode(sendExecutorBytes, (HelperUtils.ExecutorConfig));
                console.log("current: %s, peer:", chainName, peerChainName);
                console.log("executorConfig:");
                console.log(
                    "    maxMessageSize:%d, executorAddress:",
                    sendExecutorConfig.maxMessageSize,
                    sendExecutorConfig.executorAddress
                );
                //get send UlnConfig
                bytes memory ulnConfigBytes =
                    endPoint.getConfig(oftAdapterAddress, networkConfig.sendUln302, peerNetworkConfig.eid, 2);
                HelperUtils.UlnConfig memory ulnConfig = abi.decode(ulnConfigBytes, (HelperUtils.UlnConfig));
                console.log("sendConfig:");
                console.log("   confirmations:", ulnConfig.confirmations);
                console.log("   requiredDVNCount:", ulnConfig.requiredDVNCount);
                console.log("   optionalDVNCount:", ulnConfig.optionalDVNCount);
                console.log("   optionalDVNThreshold:", ulnConfig.optionalDVNThreshold);
                console.log("   requiredDVNs:");
                for (uint256 srDvnIndex = 0; srDvnIndex < ulnConfig.requiredDVNs.length; srDvnIndex++) {
                    console.log("      Dvn:", ulnConfig.requiredDVNs[srDvnIndex]);
                }
                console.log("   optionalDVNs:");
                for (uint256 soDvnIndex = 0; soDvnIndex < ulnConfig.optionalDVNs.length; soDvnIndex++) {
                    console.log("      Dvn:", ulnConfig.optionalDVNs[soDvnIndex]);
                }
                //get receive UlnConfig
                ulnConfigBytes =
                    endPoint.getConfig(oftAdapterAddress, networkConfig.receiveUIn302, peerNetworkConfig.eid, 2);
                ulnConfig = abi.decode(ulnConfigBytes, (HelperUtils.UlnConfig));
                console.log("receiveConfig:");
                console.log("    confirmations:", ulnConfig.confirmations);
                console.log("    requiredDVNCount:", ulnConfig.requiredDVNCount);
                console.log("    optionalDVNCount:", ulnConfig.optionalDVNCount);
                console.log("    optionalDVNThreshold:", ulnConfig.optionalDVNThreshold);
                console.log("    requiredDVNs:");
                for (uint256 rrDvnIndex = 0; rrDvnIndex < ulnConfig.requiredDVNs.length; rrDvnIndex++) {
                    console.log("      Dvn:", ulnConfig.requiredDVNs[rrDvnIndex]);
                }
                console.log("    optionalDVNs:");
                for (uint256 roDvnIndex = 0; roDvnIndex < ulnConfig.optionalDVNs.length; roDvnIndex++) {
                    console.log("      Dvn:", ulnConfig.optionalDVNs[roDvnIndex]);
                }
            }
        }
    }
}
