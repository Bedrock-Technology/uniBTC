// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {VaultWithoutNative} from "../contracts/VaultWithoutNative.sol";

contract Set is Script {
    address public deployer;
    address public owner;

    function setUp() public {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        owner = vm.envAddress("OWNER_ADDRESS");
    }

    //forge script fscripts/set_VaultWithoutNative.s.sol --sig 'setCap(address,address,uint256)' '0x' '0x' 1000000000 --rpc-url $RPC_ETH_SEPOLIA --account $OWNER --broadcast
    function setCap(address vaultWithoutNative, address token, uint256 cap) external {
        vm.startBroadcast(owner);
        VaultWithoutNative Ins = VaultWithoutNative(payable(vaultWithoutNative));
        Ins.setCap(token, cap);
        vm.stopBroadcast();
        console.log("set token", token);
        console.log("cap", cap);
    }

    //forge script fscripts/set_VaultWithoutNative.s.sol --sig 'allowToken(address,address[])' '0x' "[0x]" --rpc-url $RPC_ETH_SEPOLIA --account $OWNER --broadcast
    function allowToken(address vaultWithoutNative, address[] memory tokens) external {
        vm.startBroadcast(owner);
        VaultWithoutNative Ins = VaultWithoutNative(payable(vaultWithoutNative));
        Ins.allowToken(tokens);
        vm.stopBroadcast();
        console.log("enable tokens");
        for (uint256 index = 0; index < tokens.length; index++) {
            console.log("token", tokens[index]);
        }
    }
}
