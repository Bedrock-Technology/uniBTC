// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {CCIPPeer} from "../../src/ccipPeer.sol";
import {uniBTC} from "../../src/mocks/uniBTC.sol";

contract CmdCCIPPeer is Script {
    address public owner;
    address public uniBTCAddr;
    uniBTC public uniBTCIns;
    address public ccipPeerAddr;
    CCIPPeer public ccipPeerIns;
    uint64 public destinationChainSelector;

    function setUp() public {
        owner = 0xac07f2721EcD955c4370e7388922fA547E922A4f;
        if (block.chainid == 97) { //bsc-testnet
            uniBTCAddr = 0xdF1925B7A0f56a3ED7f74bE2a813Ae8bbA756e59;
            ccipPeerAddr = 0xbEfC7D6A15cc9bf839E64a16cd43ABD55Dd6633d;
            destinationChainSelector = 14767482510784806043;
        }
        if (block.chainid == 43113) { //avax-testnet
            uniBTCAddr = 0xAb3630cEf046e2dFAFd327eB8b7B96D627dEFa83;
            ccipPeerAddr = 0xD498e4aEE5585ff8099158E641c025a761ACC656;
            destinationChainSelector = 13264668187771770619;
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
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig sendToken --rpc-url https://bsc-testnet-rpc.publicnode.com --account owner --broadcast
    //fuji
    function sendToken() public {
        vm.startBroadcast(owner);
        uint256 allowance = uniBTCIns.allowance(owner, ccipPeerAddr);
        if (allowance < 10e8) {
            uniBTCIns.approve(ccipPeerAddr, 10e8);
        }
        uint fees = ccipPeerIns.estimateSendTokenFees(destinationChainSelector, 0x8cb37518330014E027396E3ED59A231FBe3B011A, 1e8);
        console.log("est fees:%d", fees);
        // send to owner, 1uniBTC
        ccipPeerIns.sendToken{value: fees}(destinationChainSelector, 0x8cb37518330014E027396E3ED59A231FBe3B011A, 1e8);
        vm.stopBroadcast();
    }

    //bsc
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig estimateSendTokenFees --rpc-url https://bsc-testnet-rpc.publicnode.com --account owner --broadcast
    //fuji
    function estimateSendTokenFees() public view {
        // send to owner, 1uniBTC
        uint fees = ccipPeerIns.estimateSendTokenFees(destinationChainSelector, 0x8cb37518330014E027396E3ED59A231FBe3B011A, 1e8);
        console.log("est fees:%d", fees);
    }
}