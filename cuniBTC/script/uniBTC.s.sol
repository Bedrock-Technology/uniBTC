// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {uniBTC} from "../mock/uniBTC.sol";
//forge script fscripts/deploy_uniBTC.s.sol --sig 'run(address,address)' $PROXY_ADMIN $OWNER_ADDRESS \
//--rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
//--verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30

contract Deploy is Script {
    function run(address proxyAdmin, address owner) external {
        vm.startBroadcast();
        uniBTC implementation = new uniBTC();
        address[] memory freeze = new address[](0);
        TransparentUpgradeableProxy uniBTCProxy = new TransparentUpgradeableProxy(
            address(implementation), proxyAdmin, abi.encodeCall(implementation.initialize, (owner, owner, freeze))
        );
        vm.stopBroadcast();

        console.log("uniBTC Proxy address:", address(uniBTCProxy));
        console.log("uniBTC Proxy Admin address:", proxyAdmin);
        console.log("uniBTC owner:", owner);
    }
}
