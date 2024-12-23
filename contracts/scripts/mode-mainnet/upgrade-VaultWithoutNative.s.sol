// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "../../lib/forge-std/src/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {VaultWithoutNative} from "../../contracts/VaultWithoutNative.sol";

//simulate
//forge script scripts/mode-mainnet/upgrade-VaultWithoutNative.s.sol:UpgradeVault --rpc-url https://mainnet.mode.network/

//mainnet
//forge script scripts/mode-mainnet/upgrade-VaultWithoutNative.s.sol:UpgradeVault --rpc-url https://mainnet.mode.network/ --account deploy --account owner --broadcast

contract UpgradeVault is Script {
    address public deploy;
    address public owner;
    ITransparentUpgradeableProxy public vaultProxy;
    ProxyAdmin public proxyAdmin;

    address[] public allowTokens;
    address[] public targetList;

    function setUp() public {
        vaultProxy = ITransparentUpgradeableProxy(0x84E5C854A7fF9F49c888d69DECa578D406C26800);
        proxyAdmin = ProxyAdmin(0xb3f925B430C60bA467F7729975D5151c8DE26698);
        owner = address(0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB);
        deploy = address(0x899c284A89E113056a72dC9ade5b60E80DD3c94f);
        //data
        allowTokens = new address[](2);
        allowTokens[0] = 0xcDd475325D6F564d27247D1DddBb0DAc6fA0a5CF; //WBTC
        allowTokens[1] = 0x59889b7021243dB5B1e065385F918316cD90D46c; //M-BTC
        //
        targetList = new address[](2);
        targetList[0] = 0xcDd475325D6F564d27247D1DddBb0DAc6fA0a5CF; // WBTC
        targetList[1] = 0x59889b7021243dB5B1e065385F918316cD90D46c; // M-BTC
    }

    function run() public {
        //deploy
        vm.startBroadcast(deploy);
        VaultWithoutNative upgradedVaultWithoutNative = new VaultWithoutNative();
        vm.stopBroadcast();
        //upgrade
        vm.startBroadcast(owner);
        proxyAdmin.upgrade(vaultProxy, address(upgradedVaultWithoutNative));
        VaultWithoutNative vault = VaultWithoutNative(payable(address(vaultProxy)));
        //set data
        vault.allowToken(allowTokens);
        vault.allowTarget(targetList);
        for (uint256 i = 0; i < targetList.length; i++) {
            vault.grantRole(vault.OPERATOR_ROLE(), targetList[i]);
        }
        vm.stopBroadcast();
        //check token
        for (uint256 i = 0; i < allowTokens.length; i++) {
            bool allowed = vault.allowedTokenList(allowTokens[i]);
            assert(allowed == true);
        }
        //check target
        for (uint256 i = 0; i < targetList.length; i++) {
            bool allowed = vault.allowedTargetList(targetList[i]);
            assert(allowed == true);
            bool hasRole = vault.hasRole(vault.OPERATOR_ROLE(), targetList[i]);
            assert(hasRole == true);
        }
        assert(vault.outOfService() == false);
    }
}
