// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {Vault} from "../src/Vault.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract Deploy is Script {
    //forge script fscripts/deploy_cVaultWithoutNative.s.sol --sig 'deploy(address,address,address)' \
    // $PROXY_ADMIN $OWNER_ADDRESS $CUNIBTC_ADDRESS \
    // --rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
    // --verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30
    function deploy(address proxyAdmin, address defaultAdmin, address cuniBTC) external {
        vm.startBroadcast();
        Vault implementation = new Vault();
        TransparentUpgradeableProxy cVaultWithoutNativeProxy = new TransparentUpgradeableProxy(
            address(implementation), proxyAdmin, abi.encodeCall(implementation.initialize, (defaultAdmin, cuniBTC))
        );
        vm.stopBroadcast();
        console.log("deploy cVaultWithoutNative proxy at", address(cVaultWithoutNativeProxy));
        console.log("proxyAdmin", proxyAdmin);
        console.log("defaultAdmin", defaultAdmin);
        console.log("cuniBTC", cuniBTC);
    }

    //forge script fscripts/deploy_cVaultWithoutNative.s.sol --sig 'upgrade(address,address)' \
    //$PROXY_ADMIN $CVAULT_ADDRESS \
    //--rpc-url $RPC_ETH_HOODI --account $OWNER --broadcast \
    //--verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30
    function upgrade(address proxyAdmin, address cvault) external {
        vm.startBroadcast();
        Vault newImplementation = new Vault();
        ProxyAdmin pAdmin = ProxyAdmin(proxyAdmin);
        pAdmin.upgrade(ITransparentUpgradeableProxy(payable(cvault)), address(newImplementation));
        vm.stopBroadcast();
    }
}
