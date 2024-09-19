pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../contracts/proxies/stateful/BitLayerNativeProxy.sol";
import "../contracts/Vault.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Test, console} from "forge-std/Test.sol";

//forge script fscripts/deploy.s.sol:BitLayerNativeProxyDeployScript -f ${HOLESKY_ARCHIVE_URL}
//more keys using --private-keys ${HOLESKY_ACCOUNT_0} --private-keys ${HOLESKY_ACCOUNT_1}
//forge script fscripts/deploy.s.sol:BitLayerNativeProxyDeployScript --broadcast --rpc-url ${HOLESKY_ARCHIVE_URL} --private-keys ${HOLESKY_ACCOUNT_0}

//forge script fscripts/deploy.s.sol:BitLayerNativeProxyDeployScript --broadcast --rpc-url ${HOLESKY_ARCHIVE_URL} --private-keys ${HOLESKY_ACCOUNT_0} --verify --etherscan-api-key ${HOLESKY_EXPLORER_API}
//verify
//

//bitlayer mainnet
//forge script fscripts/deploy.s.sol:BitLayerNativeProxyDeployScript --broadcast --rpc-url ${BITLAYER_MAIN_RPC} --private-keys ${BITLAYER_MAIN_DEPLOY_ACCOUNT} --legacy

contract BitLayerNativeProxyDeployScript is Script {
    TransparentUpgradeableProxy public bitLayerProxy;
    BitLayerNativeProxy public bitLayerNative;

    address public deploy;
    address public proxyAdmin;
    address public defaultAdmin;
    address public vault;

    function setUp() public {
        deploy = vm.addr(uint256(vm.envBytes32("BITLAYER_MAIN_DEPLOY_ACCOUNT")));
        proxyAdmin = vm.envAddress("BITLAYER_MAIN_PROXY_ADMIN");
        defaultAdmin = vm.envAddress("BITLAYER_MAIN_DEFAULT_ADMIN");
        vault = vm.envAddress("BITLAYER_MAIN_VAULT");
    }

    function run() public {
        vm.startBroadcast(deploy);
        // deploy bitLayerProxy
        BitLayerNativeProxy implementation = new BitLayerNativeProxy();
        bitLayerProxy = new TransparentUpgradeableProxy(address(implementation), proxyAdmin, abi.encodeCall(implementation.initialize, (defaultAdmin, vault)));
        bitLayerNative = BitLayerNativeProxy(payable(bitLayerProxy));
        vm.stopBroadcast();
    }
}