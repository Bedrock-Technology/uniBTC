// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {BurnProxy} from "../contracts/proxies/BurnProxy.sol";

/*

forge script -vvvv \
    --account $DEPLOYER \
    --sender $DEPLOYER_ADDRESS \
    -f $EVM_RPC \
    --broadcast \
    --verify \
    --verifier custom \
    --verifier-api-key $ETHERSCAN_API_KEY \
    --verifier-url $ETHERSCAN_API_URL \
    fscripts/deploy_burnProxy.s.sol:Deploy

*/
contract Deploy is Script {
    function run() external {
        address _deployer = vm.envAddress("DEPLOYER_ADDRESS");
        address _vault = vm.envAddress("VAULT_ADDRESS");
        address _token = vm.envAddress("TOKEN_ADDRESS");
        address _owner = vm.envAddress("OWNER_ADDRESS");

        vm.startBroadcast(_deployer);
        BurnProxy _p = new BurnProxy(_vault, _token);
        if (_owner != address(0)) {
            _p.transferOwnership(_owner);
        }
        vm.stopBroadcast();
    }
}
