// SPDX-License-Identifier: MIT

pragma solidity >=0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {uniBTCOFTAdapter} from "../contracts/uniBTCOFTAdapter.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";

contract SetOFTAdapter is Script {
    function run() external {}

    function setPeer(uint256 _chainid) external {
        // Get the current chain name based on the chain ID
        string memory chainName = HelperUtils.getNetworkConfig(block.chainid).chainName;
        string memory peerChainName = HelperUtils.getNetworkConfig(_chainid).chainName;
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
        console.log("setPeer %s, oftAdapterAddress:", chainName, oftAdapterAddress);
        console.log("peer %s, oftAdapterAddress:", peerChainName, peerOftAdapterAddress);
        console.log("peer eid:", peerNetworkConfig.eid);
    }
    //https://docs.layerzero.network/v2/developers/evm/protocol-gas-settings/default-config#custom-configuration

    function setSendConfig(uint256 _chainid, uint64 _confirmations, address[] memory _requiredDVNs) external {
        string memory chainName = HelperUtils.getNetworkConfig(block.chainid).chainName;
        string memory localPoolPath =
            string.concat(vm.projectRoot(), "/script/output/deployedOFTAdapter_", chainName, ".json");
        // Extract addresses from the JSON files
        address oftAdapterAddress =
            HelperUtils.getAddressFromJson(vm, localPoolPath, string.concat(".deployedOFTAdapter_", chainName));
        console.log(
            "setSendConfig %s, endPointAddress:", chainName, HelperUtils.getNetworkConfig(block.chainid).endPoint
        );
        console.log("peer:", HelperUtils.getNetworkConfig(_chainid).chainName);
        console.log(_confirmations);
        for (uint256 index = 0; index < _requiredDVNs.length; index++) {
            console.log(_requiredDVNs[index]);
        }
        ILayerZeroEndpointV2 endPoint = ILayerZeroEndpointV2(HelperUtils.getNetworkConfig(block.chainid).endPoint);

        address[] memory optionalDVNs = new address[](0);
        HelperUtils.UlnConfig memory ulnConfig = HelperUtils.UlnConfig({
            confirmations: _confirmations,
            requiredDVNCount: uint8(_requiredDVNs.length),
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: _requiredDVNs,
            optionalDVNs: optionalDVNs
        });
        SetConfigParam memory param = SetConfigParam({
            eid: HelperUtils.getNetworkConfig(_chainid).eid,
            configType: 2,
            config: abi.encode(ulnConfig)
        });
        SetConfigParam[] memory params = new SetConfigParam[](1);
        params[0] = param;
        address owner = vm.envAddress("OWNER_ADDRESS");
        vm.startBroadcast(owner);
        endPoint.setConfig(oftAdapterAddress, HelperUtils.getNetworkConfig(block.chainid).sendUln302, params);
        vm.stopBroadcast();
    }

    function decode() external view {
        bytes memory liter =
            hex"0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000010000000000000000000000008eebf8b423b73bfca51a1db4b7354aa0bfca91930000000000000000000000000000000000000000000000000000000000000000";
        HelperUtils.UlnConfig memory ulnConfig = abi.decode(liter, (HelperUtils.UlnConfig));
        console.log("confirmations:", ulnConfig.confirmations);
        console.log("requiredDVNCount:", ulnConfig.requiredDVNCount);
        console.log("optionalDVNCount:", ulnConfig.optionalDVNCount);
        console.log("optionalDVNThreshold:", ulnConfig.optionalDVNThreshold);
        for (uint256 index = 0; index < ulnConfig.requiredDVNs.length; index++) {
            console.log("requiredDVN:", ulnConfig.requiredDVNs[index]);
        }
        for (uint256 index = 0; index < ulnConfig.optionalDVNs.length; index++) {
            console.log("optionalDVN:", ulnConfig.optionalDVNs[index]);
        }
    }
}
