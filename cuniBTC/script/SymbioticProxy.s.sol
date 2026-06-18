// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {SymbioticProxy} from "../src/SymbioticProxy.sol";

contract Deploy is Script {
    //forge script script/SymbioticProxy.s.sol --sig 'deploy(address,address,address,address,address)' \
    // $SYMBIOTIC_VAULT $DEFAULT_STAKER_REWARDS $VAULT $UNIBTC $ADMIN \
    //--rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
    //--verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30
    function deploy(
        address symbioticVault,
        address defaultStakerRewards,
        address vault,
        address uniBTC,
        address admin
    ) external {
        vm.startBroadcast();
        SymbioticProxy symbioticProxy = new SymbioticProxy(
            symbioticVault, defaultStakerRewards, vault, uniBTC, admin
        );
        vm.stopBroadcast();

        console.log("SymbioticProxy deployed at:", address(symbioticProxy));
        console.log("owner:", symbioticProxy.owner());
        console.log("symbioticVault:", symbioticVault);
        console.log("defaultStakerRewards:", defaultStakerRewards);
        console.log("vault:", vault);
        console.log("uniBTC:", uniBTC);
        console.log("admin:", admin);
    }
}