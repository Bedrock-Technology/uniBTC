// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {Factory} from "../src/Factory.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract Deploy is Script {
    //forge script script/factory.sol --sig 'deploy(address)' \
    // $PROXY_ADMIN \
    // --rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
    // --verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30
    function deploy(address proxyAdmin) external {
        vm.startBroadcast();
        Factory implementation = new Factory();
        TransparentUpgradeableProxy factoryProxy = new TransparentUpgradeableProxy(
            address(implementation), proxyAdmin, abi.encodeCall(implementation.initialize, ())
        );
        vm.stopBroadcast();
        console.log("deploy factory proxy at", address(factoryProxy));
        console.log("proxyAdmin", proxyAdmin);
    }

    //forge script script/factory.sol --sig 'createStrategy(address,string,string,address,address)' \
    // $PROXY_ADMIN "" "" $OWNER_ADDRESS $CUNIBTC_ADDRESS \
    // --rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
    // --verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30
    function createStrategy(
        address factory,
        string memory name,
        string memory symbol,
        address defaultAdmin,
        address unibtc
    ) external {
        vm.startBroadcast();
        Factory(payable(factory)).createStrategy(name, symbol, defaultAdmin, unibtc);
        vm.stopBroadcast();
    }
}
