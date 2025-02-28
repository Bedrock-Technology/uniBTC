// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// EIP712 domain separator

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
    bytes32 salt;
}

// Example message struct
struct SendToken {
    address sender;
    address ccipPeer;
    uint256 chainid;
    uint256 destinationChainSelector;
    address recipient;
    uint256 amount;
    uint256 nonce;
}

contract EIP712Example {
    // EIP712 domain separator hash
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant SALT = "uniBTC-ccip";

    // EIP712 domain separator setup
    constructor() {
        DOMAIN_SEPARATOR = hashDomain(
            EIP712Domain({
                name: "ccipPeer",
                version: "1",
                chainId: block.chainid,
                verifyingContract: address(this),
                salt: SALT
            })
        );
    }

    // Hashes the EIP712 domain separator struct
    function hashDomain(EIP712Domain memory domain) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
                ),
                keccak256(bytes(domain.name)),
                keccak256(bytes(domain.version)),
                domain.chainId,
                domain.verifyingContract,
                domain.salt
            )
        );
    }

    // Hashes an EIP712 message struct
    function hashMessage(SendToken memory message) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256(
                    bytes(
                        "SendToken(address sender,address ccipPeer,uint256 chainid,uint256 destinationChainSelector,address recipient,uint256 amount,uint256 nonce)"
                    )
                ),
                message.sender,
                message.ccipPeer,
                message.chainid,
                message.destinationChainSelector,
                message.recipient,
                message.amount,
                message.nonce
            )
        );
    }

    // Verifies an EIP712 message signature
    function verifyMessage(SendToken memory message, bytes memory _signature) public view returns (address) {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashMessage(message)));
        address signer = ECDSA.recover(digest, _signature);
        return signer;
    }

    // Verifies an EIP712 message signature
    function verifySign(
        address _sender,
        uint64 _destinationChainSelector,
        address _recipient,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) public view returns (address) {
        SendToken memory s = SendToken({
            sender: _sender,
            ccipPeer: address(this),
            chainid: block.chainid,
            destinationChainSelector: _destinationChainSelector,
            recipient: _recipient,
            amount: _amount,
            nonce: _nonce
        });
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashMessage(s)));
        address signer = ECDSA.recover(digest, _signature);
        return signer;
    }
}
