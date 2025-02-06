// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {VaultWithoutNative} from "../contracts/VaultWithoutNative.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Depoly is Script {
    address public deployer;
    address public owner;

    function setUp() public {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        owner = vm.envAddress("OWNER_ADDRESS");
    }

    //forge script fscripts/deploy_VaultWithoutNative.s.sol --sig 'deploy(address,address)' '0x' '0x' --rpc-url $RPC_ETH_SEPOLIA --account $DEPLOYER --broadcast --verify --verifier-url $RPC_ETH_SEPOLIA_SCAN --etherscan-api-key $KEY_ETH_SEPOLIA_SCAN --delay 30
    function deploy(address proxyAdmin, address uniBTC) external {
        vm.startBroadcast(deployer);
        VaultWithoutNative implementation = new VaultWithoutNative();
        TransparentUpgradeableProxy VaultWithoutNativeProxy = new TransparentUpgradeableProxy(
            address(implementation), proxyAdmin, abi.encodeCall(implementation.initialize, (owner, uniBTC))
        );
        vm.stopBroadcast();
        console.log("deploy VaultWithoutNative proxy at", address(VaultWithoutNativeProxy));
        console.log("proxyAdmin", proxyAdmin);
        console.log("owner", owner);
        console.log("uniBTC", uniBTC);
    }
}
