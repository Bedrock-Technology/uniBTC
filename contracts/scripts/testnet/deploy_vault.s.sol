pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {VaultWithoutNative} from "../../contracts/VaultWithoutNative.sol";

//simulate
//forge script scripts/testnet/deploy_vault.s.sol:DeployVault --rpc-url https://ethereum-holesky-rpc.publicnode.com

//mainnet
//forge script scripts/testnet/deploy_vault.s.sol:DeployVault --rpc-url https://ethereum-holesky-rpc.publicnode.com --account deploy --account owner --broadcast

contract DeployVault is Script {
    address public deploy;
    address public owner;
    address[] public allowTokens;
    address[] public targetList;

    function setUp() public {
        owner = address(0xac07f2721EcD955c4370e7388922fA547E922A4f);
        deploy = address(0x8cb37518330014E027396E3ED59A231FBe3B011A);
        //data
        allowTokens = new address[](1);
        allowTokens[0] = 0x68f180fcCe6836688e9084f035309E29Bf0A2095; //WBTC
        //
        targetList = new address[](1);
        targetList[0] = 0x68f180fcCe6836688e9084f035309E29Bf0A2095; // WBTC
    }

    function run() public {
        vm.startBroadcast(deploy);
        VaultWithoutNative impVault = new VaultWithoutNative();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impVault),
            0x68f180fcCe6836688e9084f035309E29Bf0A2095,//random
            abi.encodeCall(impVault.initialize, (owner, 0xfF204e2681A6fA0e2C3FaDe68a1B28fb90E4Fc5F))
        );
        vm.stopBroadcast();
        VaultWithoutNative vault = VaultWithoutNative(payable(proxy));
        //set data
        vm.startBroadcast(owner);
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