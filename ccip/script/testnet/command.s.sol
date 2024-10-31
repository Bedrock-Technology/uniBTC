// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {CCIPPeer, IMintableContract} from "../../src/ccipPeer.sol";
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
    // function sendToken() public {
    //     vm.startBroadcast(owner);
    //     uint256 allowance = uniBTCIns.allowance(owner, ccipPeerAddr);
    //     console.log("allowance:", allowance);
    //     if (allowance < 1e8) {
    //         uniBTCIns.approve(ccipPeerAddr, 10e8);
    //     }
    //     uint256 fees =
    //         ccipPeerIns.estimateSendTokenFees(destinationChainSelector, 0x8cb37518330014E027396E3ED59A231FBe3B011A, 1e8);
    //     console.log("est fees:%d", fees);
    //     // send to owner, 1uniBTC
    //     ccipPeerIns.sendToken{value: fees}(destinationChainSelector, 0x8cb37518330014E027396E3ED59A231FBe3B011A, 1e8);
    //     vm.stopBroadcast();
    // }

    //bsc
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig targetCall --rpc-url https://bsc-testnet-rpc.publicnode.com --account owner --broadcast
    //fuji
    function targetCall() public {
        vm.startBroadcast(owner);
        uint256 allowance = uniBTCIns.allowance(owner, ccipPeerAddr);
        console.log("allowance:", allowance);
        if (allowance < 1e8) {
            uniBTCIns.approve(ccipPeerAddr, 10e8);
        }
        address target = peeruniBTCAddr;
        bytes memory callData =
            abi.encodeWithSelector(IMintableContract.mint.selector, 0x8cb37518330014E027396E3ED59A231FBe3B011A, 1e8);
        uint256 fees = ccipPeerIns.estimateTargetCallFees(destinationChainSelector, target, callData);
        console.log("est fees:%d", fees);
        // send to owner, 1uniBTC
        ccipPeerIns.targetCall{value: fees}(destinationChainSelector, target, callData);
        vm.stopBroadcast();
    }

    //bsc
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig sendTokenSign --rpc-url https://bsc-testnet-rpc.publicnode.com --account owner --broadcast
    //fuji
    //cast wallet sign --no-hash 0x8b1db885fcb6f462e6f89ee645c261e13d4b84ac2fc783e7f625c5f2ab016ec0 --account owner
    function sendTokenSign() public {
        // bytes32 digest = sha256(
        //     abi.encode(
        //         owner, ccipPeerAddr, 97, destinationChainSelector, 0x8cb37518330014E027396E3ED59A231FBe3B011A, 1e8
        //     )
        // );
        // (uint8 v, bytes32 r, bytes32 s) = vm.sign(vm.envUint("OWNER_KEY"), digest);
        // bytes memory signature = abi.encodePacked(r, s, v);
        bytes memory signature =
            hex"f805624fa5889a5684132ee96c60d85acbe48cffd727501bdbb176a7983bcdf42ca80cc36fc52446693265bf8229e402d871b9fd209b5c2afb52cfc2be1b81b71b";
        console.logBytes(signature);
        vm.startBroadcast(owner);
        uint256 allowance = uniBTCIns.allowance(owner, ccipPeerAddr);
        console.log("allowance:", allowance);
        if (allowance < 1e8) {
            uniBTCIns.approve(ccipPeerAddr, 10e8);
        }
        //sign with owner sysSign...
        uint256 fees =
            ccipPeerIns.estimateSendTokenFees(destinationChainSelector, 0x8cb37518330014E027396E3ED59A231FBe3B011A, 1e8);
        console.log("est fees:%d", fees);
        uint256 nonce = 123;
        // send to owner, 1uniBTC
        ccipPeerIns.sendToken{value: fees}(
            destinationChainSelector, 0x8cb37518330014E027396E3ED59A231FBe3B011A, 1e8, nonce, signature
        );
        vm.stopBroadcast();
    }
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig digest --rpc-url https://bsc-testnet-rpc.publicnode.com

    function digest() public view {
        bytes32 digest1 = sha256(
            abi.encode(
                owner, ccipPeerAddr, 97, destinationChainSelector, 0x8cb37518330014E027396E3ED59A231FBe3B011A, 1e8
            )
        );
        console.logBytes32(digest1);
    }

    //bsc
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig estimateSendTokenFees --rpc-url https://bsc-testnet-rpc.publicnode.com --account owner --broadcast
    //fuji
    function estimateSendTokenFees() public view {
        // send to owner, 1uniBTC
        uint256 fees =
            ccipPeerIns.estimateSendTokenFees(destinationChainSelector, 0x8cb37518330014E027396E3ED59A231FBe3B011A, 1e8);
        console.log("est fees:%d", fees);
    }

    //fuji
    //forge script script/testnet/command.s.sol:CmdCCIPPeer --sig parseFuji --rpc-url https://rpc.ankr.com/avalanche_fuji --account owner --broadcast
    function parseFuji() public {
        // send to owner, 1uniBTC
        vm.startBroadcast(owner);
        ccipPeerIns.pause();
        vm.stopBroadcast();
    }
}
