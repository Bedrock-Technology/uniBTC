// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {EIP712Example, SendToken} from "../../src/send.sol";

contract DeploySend is Script {
    function deploy() public {
        vm.startBroadcast();
        new EIP712Example();
        vm.stopBroadcast();
    }

    function verify() public view {
        EIP712Example send = EIP712Example(0xdF1925B7A0f56a3ED7f74bE2a813Ae8bbA756e59);
        SendToken memory message = SendToken({
            sender: 0xac07f2721EcD955c4370e7388922fA547E922A4f,
            ccipPeer: 0xdF1925B7A0f56a3ED7f74bE2a813Ae8bbA756e59,
            chainid: 17000,
            destinationChainSelector: 123456,
            recipient: 0xac07f2721EcD955c4370e7388922fA547E922A4f,
            amount: 100000,
            nonce: 342
        });
        address signer = send.verifyMessage(
            message,
            hex"b8bd11caafc4300eb2dc92ae5b077f26df609747ba7e67e7dcfc2609d69970c65792618090a6f6fbbbe31ac4cb1085b44abd3df1dd21b7eb49cd3e827b9a33871c"
        );
        console.logAddress(signer);
    }

    function verifysig() public view {
        EIP712Example send = EIP712Example(0xbEfC7D6A15cc9bf839E64a16cd43ABD55Dd6633d);
        SendToken memory message = SendToken({
            sender: 0xac07f2721EcD955c4370e7388922fA547E922A4f,
            ccipPeer: 0xdF1925B7A0f56a3ED7f74bE2a813Ae8bbA756e59,
            chainid: 17000,
            destinationChainSelector: 123456,
            recipient: 0xac07f2721EcD955c4370e7388922fA547E922A4f,
            amount: 100000,
            nonce: 342
        });
        address signer = send.verifySign(
            message.sender,
            uint64(message.destinationChainSelector),
            message.recipient,
            message.amount,
            message.nonce,
            hex"b08bfb3d5be1184305df2c16ad94fecab352e93da2304eb5ae0bdde51a8a0b27655960cbc7cc01a903ce73af59504c7493cb9dc7e7db057713e23de91f54295d1b"
        );
        console.logAddress(signer);
    }
}

// forge script script/mainnet/send.s.sol:DeploySend --sig 'deploy()' --rpc-url $RPC_ETH_HOLESKY --account $DEPLOYER --broadcast --verify --verifier-url $RPC_ETH_HOLESKY_SCAN --etherscan-api-key $KEY_ETH_HOLESKY_SCAN --delay 30
// forge script script/mainnet/send.s.sol:DeploySend --sig 'verify()' --rpc-url $RPC_ETH_HOLESKY
// forge script script/mainnet/send.s.sol:DeploySend --sig 'verifysig()' --rpc-url $RPC_ETH_HOLESKY
