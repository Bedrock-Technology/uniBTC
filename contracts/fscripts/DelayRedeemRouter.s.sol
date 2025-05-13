// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import {DelayRedeemRouter} from "../contracts/proxies/stateful/redeem/DelayRedeemRouter.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DelayRedeemRouterScript is Script {
    address public defaultAdmin;
    address public defaultDeployer;
    address public uniBTC = address(0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568);
    address public vault = address(0x047D41F2544B7F63A8e991aF2068a363d210d6Da);
    uint256 public redeemTimeDuration = 691200;
    uint256 public dayCap = 0;
    bool whitelistEnabled = true;
    TransparentUpgradeableProxy delayRouterProxy;
    function setUp() public {
        defaultDeployer = vm.envAddress("defaultDeployer");
        defaultAdmin = vm.envAddress("defaultAdmin");
        DelayRedeemRouter delayRouterImp = new DelayRedeemRouter();
        delayRouterProxy = new TransparentUpgradeableProxy(
            address(delayRouterImp),
            defaultDeployer,
            abi.encodeCall(
                delayRouterImp.initialize,
                (
                    defaultAdmin,
                    uniBTC,
                    vault,
                    redeemTimeDuration,
                    whitelistEnabled
                )
            )
        );
    }

    function run() external {
        uint256 deployer = vm.envUint("deployer");
        vm.startBroadcast(deployer);
        setUp();
        vm.stopBroadcast();
    }
}
