// SPDX-License-Identifier: MIT

pragma solidity >=0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {uniBTCOFTAdapter} from "../contracts/uniBTCOFTAdapter.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {
    IOAppOptionsType3,
    EnforcedOptionParam
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

contract SetOFTAdapter is Script {
    using OptionsBuilder for bytes;

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
        console.log("current: %s, peer:", chainName, peerChainName);
        console.log("peer %s, oftAdapterAddress:", peerChainName, peerOftAdapterAddress);
        console.log("peer eid:", peerNetworkConfig.eid);
    }
    //https://docs.layerzero.network/v2/developers/evm/protocol-gas-settings/default-config#custom-configuration

    function setConfig(
        uint256 _chainid,
        uint64 _confirmations,
        address[] memory _requiredDVNs,
        address[] memory _optionalDVNs,
        uint8 _optionalThreshold
    ) external {
        _requiredDVNs = _sort(_requiredDVNs);
        _optionalDVNs = _sort(_optionalDVNs);
        string memory chainName = HelperUtils.getNetworkConfig(block.chainid).chainName;
        string memory localPoolPath =
            string.concat(vm.projectRoot(), "/script/output/deployedOFTAdapter_", chainName, ".json");
        // Extract addresses from the JSON files
        address oftAdapterAddress =
            HelperUtils.getAddressFromJson(vm, localPoolPath, string.concat(".deployedOFTAdapter_", chainName));
        console.log("current %s, peer:", chainName, HelperUtils.getNetworkConfig(_chainid).chainName);
        console.log("confirmations:", _confirmations);
        console.log("requiredDVNs:", _requiredDVNs.length);
        for (uint256 index = 0; index < _requiredDVNs.length; index++) {
            console.log("  requiredDVN:", _requiredDVNs[index]);
        }
        console.log("optionalDVNs:", _optionalDVNs.length);
        console.log("optionalThreshold:", _optionalThreshold);
        for (uint256 index = 0; index < _optionalDVNs.length; index++) {
            console.log("  optionDVN:", _optionalDVNs[index]);
        }

        ILayerZeroEndpointV2 endPoint = ILayerZeroEndpointV2(HelperUtils.getNetworkConfig(block.chainid).endPoint);

        HelperUtils.UlnConfig memory ulnConfig = HelperUtils.UlnConfig({
            confirmations: _confirmations,
            requiredDVNCount: uint8(_requiredDVNs.length),
            optionalDVNCount: uint8(_optionalDVNs.length),
            optionalDVNThreshold: _optionalThreshold,
            requiredDVNs: _requiredDVNs,
            optionalDVNs: _optionalDVNs
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
        endPoint.setConfig(oftAdapterAddress, HelperUtils.getNetworkConfig(block.chainid).receiveUIn302, params);
        vm.stopBroadcast();
    }

    function setEnforceOption(uint256 _chainid) external {
        string memory chainName = HelperUtils.getNetworkConfig(block.chainid).chainName;
        string memory localPoolPath =
            string.concat(vm.projectRoot(), "/script/output/deployedOFTAdapter_", chainName, ".json");
        // Extract addresses from the JSON files
        address oftAdapterAddress =
            HelperUtils.getAddressFromJson(vm, localPoolPath, string.concat(".deployedOFTAdapter_", chainName));
        console.log("current %s, peer:", chainName, HelperUtils.getNetworkConfig(_chainid).chainName);
        IOAppOptionsType3 oftAdapter = IOAppOptionsType3(oftAdapterAddress);
        uint32 peerEid = HelperUtils.getNetworkConfig(_chainid).eid;
        bytes memory option = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        console.logBytes(option);
        EnforcedOptionParam memory param1 = EnforcedOptionParam(peerEid, 1, option);
        EnforcedOptionParam memory param2 = EnforcedOptionParam(peerEid, 2, option);

        EnforcedOptionParam[] memory EnforcedOptionParams = new EnforcedOptionParam[](2);
        EnforcedOptionParams[0] = param1;
        EnforcedOptionParams[1] = param2;

        address owner = vm.envAddress("OWNER_ADDRESS");
        vm.startBroadcast(owner);
        oftAdapter.setEnforcedOptions(EnforcedOptionParams);
        vm.stopBroadcast();
    }

    function addWhitelist(address[] memory _accounts) external {
        string memory chainName = HelperUtils.getNetworkConfig(block.chainid).chainName;
        // Construct paths to the configuration and local pool JSON files
        string memory localPoolPath =
            string.concat(vm.projectRoot(), "/script/output/deployedOFTAdapter_", chainName, ".json");
        // Extract addresses from the JSON files
        address oftAdapterAddress =
            HelperUtils.getAddressFromJson(vm, localPoolPath, string.concat(".deployedOFTAdapter_", chainName));
        address owner = vm.envAddress("OWNER_ADDRESS");
        vm.startBroadcast(owner);
        uniBTCOFTAdapter oftAdapter = uniBTCOFTAdapter(oftAdapterAddress);
        oftAdapter.addToWhitelist(_accounts);
        vm.stopBroadcast();
        console.log("current: %s", chainName);
        console.log("add accounts to whitelist:");
        for (uint256 index = 0; index < _accounts.length; index++) {
            console.log("account: %s", _accounts[index]);
        }
    }

    function decode(bytes memory _liter) external view {
        HelperUtils.UlnConfig memory ulnConfig = abi.decode(_liter, (HelperUtils.UlnConfig));
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

    function _sort(address[] memory a) public pure returns (address[] memory) {
        // note that uint can not take negative value
        for (uint256 i = 1; i < a.length; i++) {
            address temp = a[i];
            uint256 j = i;
            while ((j >= 1) && (temp < a[j - 1])) {
                a[j] = a[j - 1];
                j--;
            }
            a[j] = temp;
        }
        return (a);
    }
}
