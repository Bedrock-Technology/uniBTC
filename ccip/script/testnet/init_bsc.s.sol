// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {CCIPPeer} from "../../src/ccipPeer.sol";

//simulate
//forge script script/testnet/init_bsc.s.sol:InitCCIPPeer --rpc-url https://bsc-testnet-rpc.publicnode.com

//testnet
//forge script script/testnet/init_bsc.s.sol:InitCCIPPeer --rpc-url https://bsc-testnet-rpc.publicnode.com --account owner --broadcast

contract InitCCIPPeer is Script {
    address public deploy;
    address public owner;
    address public admin;
    address public uniBTC;
    address public router = 0xE1053aE1857476f36A3C62580FF9b016E8EE8F6f;
    address public CCIPPeerAddress;
    CCIPPeer public ccipPeer;
    uint64 public sourceSelector;
    uint64 public destSelector;
    address public fujiPeer;

    uint64 public selfsourceSelector;
    uint64 public selfdestSelector;
    address public selfbscPeer;

    function setUp() public {
        owner = 0xac07f2721EcD955c4370e7388922fA547E922A4f;
        CCIPPeerAddress = 0x71c1A45eBa172d11c9e52dDF8BADD4b3A585b517;
        ccipPeer = CCIPPeer(payable(CCIPPeerAddress));
        //peer fuji
        sourceSelector = 14767482510784806043;
        destSelector = 14767482510784806043;
        fujiPeer = 0x3C4C2f4d6e45C23DF2B02b94168A5f0d378faeAe;

        //self bsc
        selfsourceSelector = 13264668187771770619;
        selfdestSelector = 13264668187771770619;
        selfbscPeer = 0x71c1A45eBa172d11c9e52dDF8BADD4b3A585b517;
    }

    function run() public {
        console.log("minAmt:%d", ccipPeer.minTransferAmt());
        vm.startBroadcast(owner);
        ccipPeer.allowlistSourceChain(sourceSelector, fujiPeer);
        ccipPeer.allowlistDestinationChain(destSelector, fujiPeer);
        ccipPeer.allowlistSourceChain(selfsourceSelector, selfbscPeer);
        ccipPeer.allowlistDestinationChain(selfdestSelector, selfbscPeer);
        vm.stopPrank();
        console.log("source:%s", ccipPeer.allowlistedSourceChains(sourceSelector));
        console.log("dest:%s", ccipPeer.allowlistedDestinationChains(destSelector));
        console.log("source:%s", ccipPeer.allowlistedSourceChains(selfsourceSelector));
        console.log("dest:%s", ccipPeer.allowlistedDestinationChains(selfdestSelector));
    }
}
