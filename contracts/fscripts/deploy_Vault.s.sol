// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {Vault} from "../contracts/Vault.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Depoly is Script {
    address public deployer;
    address public owner;

    function setUp() public {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        owner = vm.envAddress("OWNER_ADDRESS");
    }

    //forge script fscripts/deploy_Vault.s.sol --sig 'deploy(address,address)' '0x' '0x' --rpc-url $RPC_ETH_SEPOLIA --account $DEPLOYER --broadcast --verify --verifier-url $RPC_ETH_SEPOLIA_SCAN --etherscan-api-key $KEY_ETH_SEPOLIA_SCAN --delay 30
    function deploy(address proxyAdmin, address uniBTC) external {
        vm.startBroadcast(deployer);
        Vault implementation = new Vault();
        TransparentUpgradeableProxy VaultProxy = new TransparentUpgradeableProxy(
            address(implementation), proxyAdmin, abi.encodeCall(implementation.initialize, (owner, uniBTC))
        );
        vm.stopBroadcast();
        console.log("deploy Vault proxy at", address(VaultProxy));
        console.log("proxyAdmin", proxyAdmin);
        console.log("owner", owner);
        console.log("uniBTC", uniBTC);
    }
}
