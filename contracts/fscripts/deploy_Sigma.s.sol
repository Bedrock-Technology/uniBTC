// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Sigma} from "../contracts/Sigma.sol";

contract Depoly is Script {
    address public deployer;
    address public owner;

    function setUp() public {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        owner = vm.envAddress("OWNER_ADDRESS");
    }

    //forge script fscripts/deploy_Sigma.s.sol --sig 'deploy(address)' '0x' --rpc-url $RPC_ETH_SEPOLIA --account $DEPLOYER --broadcast --verify --verifier-url $RPC_ETH_SEPOLIA_SCAN --etherscan-api-key $KEY_ETH_SEPOLIA_SCAN --delay 30
    function deploy(address proxyAdmin) external {
        vm.startBroadcast(deployer);
        Sigma implementation = new Sigma();
        TransparentUpgradeableProxy SigmaProxy = new TransparentUpgradeableProxy(
            address(implementation), proxyAdmin, abi.encodeCall(implementation.initialize, (owner))
        );
        vm.stopBroadcast();
        console.log("deploy Sigma proxy at", address(SigmaProxy));
        console.log("proxyAdmin", proxyAdmin);
        console.log("owner", owner);
    }
}
