// SPDX-License-Identifier: MIT

pragma solidity >=0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {uniBTCOFTAdapter} from "../contracts/uniBTCOFTAdapter.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {uniBTC} from "../contracts/mocks/uniBTC.sol";

contract SetOFTAdapter is Script {
    using OptionsBuilder for bytes;

    function run() external {}

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function sendToken(address _recipient, uint256 _amount, uint256 _chainid) external {
        // Get the current chain name based on the chain ID
        string memory chainName = HelperUtils.getNetworkConfig(block.chainid).chainName;
        string memory peerChainName = HelperUtils.getNetworkConfig(_chainid).chainName;
        string memory localPoolPath =
            string.concat(vm.projectRoot(), "/script/output/deployedOFTAdapter_", chainName, ".json");
        // Extract addresses from the JSON files
        address oftAdapterAddress =
            HelperUtils.getAddressFromJson(vm, localPoolPath, string.concat(".deployedOFTAdapter_", chainName));
        uniBTCOFTAdapter adapter = uniBTCOFTAdapter(oftAdapterAddress);

        HelperUtils.NetworkConfig memory peerNetworkConfig = HelperUtils.getNetworkConfig(_chainid);
        HelperUtils.NetworkConfig memory networkConfig = HelperUtils.getNetworkConfig(block.chainid);

        SendParam memory sendParam = SendParam(
            peerNetworkConfig.eid,
            addressToBytes32(_recipient),
            _amount,
            _amount,
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0),
            "",
            ""
        );
        MessagingFee memory fee = adapter.quoteSend(sendParam, false);

        address owner = vm.envAddress("OWNER_ADDRESS");
        vm.startBroadcast(owner);
        uint256 allowance = uniBTC(networkConfig.uniBTC).allowance(owner, oftAdapterAddress);
        if (allowance < _amount) {
            uniBTC(networkConfig.uniBTC).approve(oftAdapterAddress, _amount);
        }
        console.log("SendParam:");
        console.log("  dstEid:", sendParam.dstEid);
        console.log("  to:");
        console.logBytes32(sendParam.to);
        console.log("  amountLD:", sendParam.amountLD);
        console.log("  minAmountLS:", sendParam.minAmountLD);
        console.log("  extraOptions:");
        console.logBytes(sendParam.extraOptions);
        console.log("  composeMsg:");
        console.logBytes(sendParam.composeMsg);
        console.log("  oftCmd:");
        console.logBytes(sendParam.oftCmd);
        console.log("Fee:");
        console.log("  nativeFee:", fee.nativeFee);
        console.log("  lzTokenFee:", fee.lzTokenFee);
        console.log("refundAddress:", owner);
        adapter.send{value: fee.nativeFee}(sendParam, fee, payable(owner));
        vm.stopBroadcast();
        console.log("send %s, to:", chainName, peerChainName);
        console.log("fee:", fee.nativeFee);
        console.log("recipient:%s, amount:", _recipient, _amount);
    }
}
