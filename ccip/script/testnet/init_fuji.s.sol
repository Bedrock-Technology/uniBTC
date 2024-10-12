// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {CCIPPeer} from "../../src/ccipPeer.sol";

//simulate
//forge script script/testnet/init_fuji.s.sol:InitCCIPPeer --rpc-url https://avalanche-fuji-c-chain-rpc.publicnode.com

//testnet
//forge script script/testnet/init_fuji.s.sol:InitCCIPPeer --rpc-url https://avalanche-fuji-c-chain-rpc.publicnode.com --account owner --broadcast

contract InitCCIPPeer is Script {
    address public deploy;
    address public owner;
    address public admin;
    address public uniBTC;
    address public router = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    address public CCIPPeerAddress;
    CCIPPeer public ccipPeer;
    uint64 public sourceSelector;
    uint64 public destSelector;
    address public bscPeer;

    function setUp() public {
        owner = 0xac07f2721EcD955c4370e7388922fA547E922A4f;
        CCIPPeerAddress = 0xD498e4aEE5585ff8099158E641c025a761ACC656;
        ccipPeer = CCIPPeer(payable(CCIPPeerAddress));
        //peer bsc
        sourceSelector = 13264668187771770619;
        destSelector = 13264668187771770619;
        bscPeer = 0xbEfC7D6A15cc9bf839E64a16cd43ABD55Dd6633d;
    }

    function run() public {
        console.log("minAmt:%d", ccipPeer.minTransferAmt());
        vm.startBroadcast(owner);
        ccipPeer.allowlistSourceChain(sourceSelector, bscPeer);
        ccipPeer.allowlistDestinationChain(destSelector, bscPeer);
        vm.stopPrank();
        console.log("source:%s", ccipPeer.allowlistedSourceChains(sourceSelector));
        console.log("dest:%s", ccipPeer.allowlistedDestinationChains(destSelector));
    }
}
