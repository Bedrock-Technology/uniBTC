// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {SymbioticProxy} from "../src/SymbioticProxy.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract Deploy is Script {
    //forge script script/SymbioticProxy.s.sol --sig 'deploy(address,address,address,address,address,address)' \
    // $PROXY_ADMIN $SYMBIOTIC_VAULT $DEFAULT_STAKER_REWARDS $VAULT $UNIBTC $ADMIN \
    //--rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
    //--verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30
    function deploy(
        address proxyAdmin,
        address symbioticVault,
        address defaultStakerRewards,
        address vault,
        address uniBTC,
        address admin
    ) external {
        vm.startBroadcast();
        SymbioticProxy implementation = new SymbioticProxy();
        TransparentUpgradeableProxy symbioticProxyProxy = new TransparentUpgradeableProxy(
            address(implementation),
            proxyAdmin,
            abi.encodeCall(
                implementation.initialize,
                (symbioticVault, defaultStakerRewards, vault, uniBTC, admin)
            )
        );
        vm.stopBroadcast();

        console.log("SymbioticProxy implementation at:", address(implementation));
        console.log("SymbioticProxy proxy at:", address(symbioticProxyProxy));
        console.log("proxyAdmin:", proxyAdmin);
        console.log("symbioticVault:", symbioticVault);
        console.log("defaultStakerRewards:", defaultStakerRewards);
        console.log("vault:", vault);
        console.log("uniBTC:", uniBTC);
        console.log("admin:", admin);
    }

    //forge script script/SymbioticProxy.s.sol --sig 'upgrade(address,address)' \
    // $PROXY_ADMIN $SYMBIOTIC_PROXY_ADDRESS \
    //--rpc-url $RPC_ETH_HOODI --account $OWNER --broadcast \
    //--verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30
    function upgrade(address proxyAdmin, address symbioticProxyAddress) external {
        vm.startBroadcast();
        SymbioticProxy newImplementation = new SymbioticProxy();
        ProxyAdmin pAdmin = ProxyAdmin(proxyAdmin);
        pAdmin.upgrade(ITransparentUpgradeableProxy(payable(symbioticProxyAddress)), address(newImplementation));
        vm.stopBroadcast();

        console.log("SymbioticProxy upgraded to new implementation at:", address(newImplementation));
    }
}