pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {VaultWithoutNative} from "../../contracts/VaultWithoutNative.sol";

//simulate
//forge script scripts/arbitrum-mainnet/upgrade-VaultWithoutNative.s.sol:UpgradeVault --rpc-url https://arb1.arbitrum.io/rpc

//mainnet
//forge script scripts/arbitrum-mainnet/upgrade-VaultWithoutNative.s.sol:UpgradeVault --rpc-url https://arb1.arbitrum.io/rpc --account deploy --account owner --broadcast

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
        allowTokens = new address[](1);
        allowTokens[0] = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f; //FBTC
        //
        targetList = new address[](1);
        targetList[0] = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
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
