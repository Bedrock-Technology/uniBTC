// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
//forge script fscripts/deploy_proxyAdmin.s.sol --sig 'run(address)' $OWNER_ADDRESS --rpc-url $RPC_ETH_HOODI --account $DEPLOYER --broadcast \
//--verify --verifier-url $RPC_ETH_HOODI_SCAN --etherscan-api-key $KEY_ETH_HOODI_SCAN --delay 30

contract Deploy is Script {
    function run(address owner) external {
        vm.startBroadcast();
        ProxyAdmin adminInstance = new ProxyAdmin();
        adminInstance.transferOwnership(owner);
        vm.stopBroadcast();

        console.log("ProxyAdmin address:", address(adminInstance));
        console.log("ProxyAdmin owner:", owner);
    }
}
