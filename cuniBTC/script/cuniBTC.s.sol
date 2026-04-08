// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {cuniBTC} from "../src/cuniBTC.sol";
//forge script fscripts/deploy_cuniBTC.s.sol --sig 'run(address,address,address)' \
//$PROXY_ADMIN $OWNER_ADDRESS $OWNER_ADDRESS \
//--rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
//--verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30

contract Deploy is Script {
    function run(address proxyAdmin, address defaultAdmin, address minter) external {
        vm.startBroadcast();
        cuniBTC implementation = new cuniBTC();
        TransparentUpgradeableProxy cuniBTCProxy = new TransparentUpgradeableProxy(
            address(implementation),
            proxyAdmin,
            abi.encodeCall(implementation.initialize, (defaultAdmin, minter, "uniBTC", "cuniBTC"))
        );
        vm.stopBroadcast();

        console.log("cuniBTC Proxy address:", address(cuniBTCProxy));
        console.log("cuniBTC Proxy Admin address:", proxyAdmin);
        console.log("cuniBTC default admin:", defaultAdmin);
        console.log("cuniBTC minter:", minter);
    }

    //forge script fscripts/deploy_cuniBTC.s.sol --sig 'upgrade(address,address)' \
    //$PROXY_ADMIN $CUNIBTC_ADDRESS \
    //--rpc-url $RPC_ETH_HOODI --account $OWNER --broadcast \
    //--verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30
    function upgrade(address proxyAdmin, address cuniBTCProxy) external {
        vm.startBroadcast();
        cuniBTC newImplementation = new cuniBTC();
        ProxyAdmin pAdmin = ProxyAdmin(proxyAdmin);
        pAdmin.upgrade(ITransparentUpgradeableProxy(payable(cuniBTCProxy)), address(newImplementation));
        vm.stopBroadcast();

        console.log("cuniBTC upgraded to new implementation:", address(newImplementation));
    }
}
