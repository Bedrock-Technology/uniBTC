// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Digest is Script {
    // function digest() public view {
    //     address _sender = vm.envAddress("SENDER");
    //     address _ccipPeer = vm.envAddress("CCIPPEER");
    //     uint256 _chainid = vm.envUint("CHAIN_ID");
    //     uint256 _destinationChainSelector = vm.envUint("DEST_CHAIN_SELECTOR");
    //     address _recipient = vm.envAddress("RECIPIENT");
    //     uint256 _amount = vm.envUint("AMOUNT");
    //     uint256 _nonce = vm.envUint("NONCE");

    //     bytes32 digest1 =
    //         sha256(abi.encode(_sender, _ccipPeer, _chainid, _destinationChainSelector, _recipient, _amount, _nonce));
    //     console.logBytes32(digest1);
    // }
    function digest(
        address _sender,
        address _ccipPeer,
        uint256 _chainid,
        uint256 _destinationChainSelector,
        address _recipient,
        uint256 _amount,
        uint256 _nonce
    ) public pure {
        bytes32 digest1 =
            sha256(abi.encode(_sender, _ccipPeer, _chainid, _destinationChainSelector, _recipient, _amount, _nonce));
        console.logBytes32(digest1);
    }

    function sign(
        address _sender,
        address _ccipPeer,
        uint256 _chainid,
        uint256 _destinationChainSelector,
        address _recipient,
        uint256 _amount,
        uint256 _nonce
    ) public pure {
        bytes32 digest1 =
            sha256(abi.encode(_sender, _ccipPeer, _chainid, _destinationChainSelector, _recipient, _amount, _nonce));
        console.log("nonce:", _nonce);
        console.log("digest:");
        console.logBytes32(digest1);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(digest1);
        bytes memory signature = abi.encodePacked(r, s, v);
        console.log("sign:");
        console.logBytes(signature);
        //verify
        console.log("----------------------------");
        address signer = ECDSA.recover(digest1, signature);
        console.log("signer:", signer);
    }
}

//forge script script/mainnet/digest.s.sol:Digest --sig 'digest(address,address,uint256,uint256,address,uint256,uint256)' \
//0xac07f2721EcD955c4370e7388922fA547E922A4f \
//0xac07f2721EcD955c4370e7388922fA547E922A4f \
//1 \
//1673871237479749969 \
//0xac07f2721EcD955c4370e7388922fA547E922A4f \
//10000 \
//4545

//cast wallet sign --no-hash 0x08215571639793cda8a833c51ee9b3b79fe187f6257a2531a9061ae2c5d9dd4f --account owner

// function sign(
//     address _sender,
//     address _ccipPeer,
//     uint256 _chainid,
//     uint256 _destinationChainSelector,
//     address _recipient,
//     uint256 _amount,
//     uint256 _nonce
// ) public pure
//forge script script/mainnet/digest.s.sol:Digest --sig 'sign(address,address,uint256,uint256,address,uint256,uint256)' \
//0xac07f2721EcD955c4370e7388922fA547E922A4f \
//0xac07f2721EcD955c4370e7388922fA547E922A4f \
//1 \
//1673871237479749969 \
//0xac07f2721EcD955c4370e7388922fA547E922A4f \
//10000 \
//$RANDOM \
//--account owner
