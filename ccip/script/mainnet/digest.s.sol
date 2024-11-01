pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

contract Digest is Script {
    function digest() public view {
        address _sender = vm.envAddress("SENDER");
        address _ccipPeer = vm.envAddress("CCIPPEER");
        uint256 _chainid = vm.envUint("CHAIN_ID");
        uint256 _destinationChainSelector = vm.envUint("DEST_CHAIN_SELECTOR");
        address _recipient = vm.envAddress("RECIPIENT");
        uint256 _amount = vm.envUint("AMOUNT");
        uint256 _nonce = vm.envUint("NONCE");

        bytes32 digest1 =
            sha256(abi.encode(_sender, _ccipPeer, _chainid, _destinationChainSelector, _recipient, _amount, _nonce));
        console.logBytes32(digest1);
    }
}

// forge script script/main/sign.s.sol:Digest --sig digest
