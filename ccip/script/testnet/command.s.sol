// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {CCIPPeer} from "../../src/ccipPeer.sol";
import {uniBTC} from "../../src/mocks/uniBTC.sol";

//sendtoken:
//sendtokensing:
//target call:

contract CmdCCIPPeer is Script {
    address public owner;
    address public uniBTCAddr;
    uniBTC public uniBTCIns;
    address public ccipPeerAddr;
    CCIPPeer public ccipPeerIns;
    uint64 public destinationChainSelector;
    uint64 public selfdestinationChainSelector;
    address public peeruniBTCAddr;

    function setUp() public {
        owner = 0xac07f2721EcD955c4370e7388922fA547E922A4f;
        if (block.chainid == 97) {
            //bsc-testnet
            uniBTCAddr = 0xF04Cb14F13144505eB93a165476f1259A1538303;
            ccipPeerAddr = 0x71c1A45eBa172d11c9e52dDF8BADD4b3A585b517;
            destinationChainSelector = 14767482510784806043;
            peeruniBTCAddr = 0x285AFd3688a20aa854b9AED89e538CF85177b458;
            selfdestinationChainSelector = 13264668187771770619;
        }
        if (block.chainid == 43113) {
            //avax-testnet
            uniBTCAddr = 0x285AFd3688a20aa854b9AED89e538CF85177b458;
            ccipPeerAddr = 0x3C4C2f4d6e45C23DF2B02b94168A5f0d378faeAe;
            destinationChainSelector = 13264668187771770619;
            peeruniBTCAddr = 0xF04Cb14F13144505eB93a165476f1259A1538303;
            selfdestinationChainSelector = 14767482510784806043;
        }
        uniBTCIns = uniBTC(uniBTCAddr);
        ccipPeerIns = CCIPPeer(payable(ccipPeerAddr));
    }
    //bsc
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig mintuniBTC --rpc-url https://bsc-testnet-rpc.publicnode.com --account owner --broadcast
    //fuji
    function mintuniBTC() public {
        vm.startBroadcast(owner);
        uniBTCIns.mint(owner, 10e8); //10.0
        vm.stopBroadcast();
        console.log("owner uniBTC bal:%d", uniBTCIns.balanceOf(owner));
    }

    //bsc
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig grantuniBTCMinterRole --rpc-url https://bsc-testnet-rpc.publicnode.com --account owner --broadcast
    //fuji
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig grantuniBTCMinterRole --rpc-url https://avalanche-fuji-c-chain-rpc.publicnode.com --account owner --broadcast
    function grantuniBTCMinterRole() public {
        vm.startBroadcast(owner);
        uniBTCIns.grantRole(uniBTCIns.MINTER_ROLE(), ccipPeerAddr);
        vm.stopBroadcast();
    }

    //bsc
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig targetAllowList --rpc-url https://bsc-testnet-rpc.publicnode.com --account owner --broadcast
    //fuji
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig targetAllowList --rpc-url https://avalanche-fuji-c-chain-rpc.publicnode.com --account owner --broadcast
    function targetAllowList() public {
        vm.startBroadcast(owner);
        ccipPeerIns.allowlistTargetTokens(destinationChainSelector, peeruniBTCAddr);
        vm.stopBroadcast();
    }

    //bsc
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig sendToken --rpc-url https://bsc-testnet-rpc.publicnode.com --account owner --broadcast
    //fuji
    function sendToken() public {
        vm.startBroadcast(owner);
        uint256 allowance = uniBTCIns.allowance(owner, ccipPeerAddr);
        if (allowance < 10e8) {
            uniBTCIns.approve(ccipPeerAddr, 10e8);
        }
        uint fees = ccipPeerIns.estimateSendTokenFees(
            destinationChainSelector,
            0x8cb37518330014E027396E3ED59A231FBe3B011A,
            1e8
        );
        console.log("est fees:%d", fees);
        // send to owner, 1uniBTC
        ccipPeerIns.sendToken{value: fees}(
            destinationChainSelector,
            0x8cb37518330014E027396E3ED59A231FBe3B011A,
            1e8
        );
        vm.stopBroadcast();
    }

    //bsc
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig estimateSendTokenFees --rpc-url https://bsc-testnet-rpc.publicnode.com --account owner --broadcast
    //fuji
    function estimateSendTokenFees() public view {
        // send to owner, 1uniBTC
        uint fees = ccipPeerIns.estimateSendTokenFees(
            destinationChainSelector,
            0x8cb37518330014E027396E3ED59A231FBe3B011A,
            1e8
        );
        console.log("est fees:%d", fees);
    }
}


