// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import "../src/cuniBTC.sol";
import "../src/Vault.sol";
import "../src/Airdrop.sol";
import "../src/DelayRedeemRouter.sol";

contract Deploy is Script {
    //forge script script/defaultImpl.s.sol --sig 'deploy()' \
    // --rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
    // --verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30
    function deploy() external {
        vm.startBroadcast();
        cuniBTC cuniBTCimplementation = new cuniBTC();
        Vault vaultImpl = new Vault();
        Airdrop airdropImpl = new Airdrop();
        DelayRedeemRouter delayRedeemRouterImpl = new DelayRedeemRouter();

        vm.stopBroadcast();
        console.log("deploy cuniBTC implementation at", address(cuniBTCimplementation));
        console.log("deploy vault implementation at", address(vaultImpl));
        console.log("deploy airdrop implementation at", address(airdropImpl));
        console.log("deploy delayredeemrouter implementation at", address(delayRedeemRouterImpl));
    }

    //forge script script/defaultImpl.s.sol --sig 'vaultDeploy()' \
    // --rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
    // --verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30
    function vaultDeploy() external {
        vm.startBroadcast();
        Vault vaultImpl = new Vault();
        vm.stopBroadcast();
        console.log("deploy vault implementation at", address(vaultImpl));
    }

    //forge script script/defaultImpl.s.sol --sig 'airdropDeploy()' \
    // --rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
    // --verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30
    function airdropDeploy() external {
        vm.startBroadcast();
        Airdrop airdropImpl = new Airdrop();
        vm.stopBroadcast();
        console.log("deploy airdrop implementation at", address(airdropImpl));
    }

    //forge script script/defaultImpl.s.sol --sig 'redeemDeploy()' \
    // --rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
    // --verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30
    function redeemDeploy() external {
        vm.startBroadcast();
        DelayRedeemRouter redeemImpl = new DelayRedeemRouter();
        vm.stopBroadcast();
        console.log("deploy redeem implementation at", address(redeemImpl));
    }
}
