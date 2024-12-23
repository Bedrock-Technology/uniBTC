// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "../../lib/forge-std/src/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {VaultWithoutNative} from "../../contracts/VaultWithoutNative.sol";

//simulate
//forge script scripts/optimism-mainnet/upgrade-VaultWithoutNative.s.sol:UpgradeVault --rpc-url https://rpc.ankr.com/optimism

//mainnet
//forge script scripts/optimism-mainnet/upgrade-VaultWithoutNative.s.sol:UpgradeVault --rpc-url https://rpc.ankr.com/optimism --account deploy --account owner --broadcast

contract UpgradeVault is Script {
    address public deploy;
    address public owner;
    ITransparentUpgradeableProxy public vaultProxy;
    ProxyAdmin public proxyAdmin;

    address[] public allowTokens;
    address[] public targetList;

    function setUp() public {
        vaultProxy = ITransparentUpgradeableProxy(0xF9775085d726E782E83585033B58606f7731AB18);
        proxyAdmin = ProxyAdmin(0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19);
        owner = address(0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB);
        deploy = address(0x899c284A89E113056a72dC9ade5b60E80DD3c94f);
        //data
        allowTokens = new address[](1);
        allowTokens[0] = 0x68f180fcCe6836688e9084f035309E29Bf0A2095; //WBTC
        //
        targetList = new address[](1);
        targetList[0] = 0x68f180fcCe6836688e9084f035309E29Bf0A2095; // WBTC
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
