// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {CCIPPeer} from "../../src/ccipPeer.sol";
import {uniBTC} from "../../src/mocks/uniBTC.sol";

//simulate
//forge script script/mainnet/opt.s.sol:DeployCCIPPeer --rpc-url https://rpc.ankr.com/optimism --account deploy

//mainnet deploy
//forge script script/mainnet/opt.s.sol:DeployCCIPPeer --rpc-url https://rpc.ankr.com/optimism --account deploy --broadcast  --verify --verifier-url 'https://api-optimistic.etherscan.io/api' --etherscan-api-key "" --delay 30
//set ArbPeer
//forge script script/mainnet/opt.s.sol:DeployCCIPPeer --sig 'initArbPeer()' --rpc-url https://api-optimistic.etherscan.io/api --account owner --broadcast

contract DeployCCIPPeer is Script {
    address public deploy;
    address public owner;
    address public router;
    address public proxyAdmin;
    address public uniBTCAddress;
    // TODO modify when contract was deployed.
    address public ccipPeerAddress = address(0);
    address public sysSigner = 0x9ffB3beFBfBe535E68b2d1DDd79aa0e1ef8dC863;

    function setUp() public {
        deploy = 0x899c284A89E113056a72dC9ade5b60E80DD3c94f;
        owner = 0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB;
        proxyAdmin = 0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19;
        uniBTCAddress = 0x93919784C523f39CACaa98Ee0a9d96c3F32b593e;
        router = 0x3206695CaE29952f4b0c22a169725a865bc8Ce0f;
    }

    // default function to run, must exist.
    function run() public {
        vm.startBroadcast(deploy);
        //deploy ccipPeer
        CCIPPeer ccipPeerImplementation = new CCIPPeer(router);

        new TransparentUpgradeableProxy(
            address(ccipPeerImplementation),
            proxyAdmin,
            abi.encodeCall(ccipPeerImplementation.initialize, (owner, uniBTCAddress, sysSigner))
        );
        vm.stopBroadcast();
    }

    function initOpPeer() public {
        //TODO modify
        address peerCcip = address(0);
        address peeruniBTC = 0x93919784C523f39CACaa98Ee0a9d96c3F32b593e;
        uint64 peerchainSelect = 3734403246176062136;
        vm.startBroadcast(owner);
        CCIPPeer(payable(ccipPeerAddress)).allowlistSourceChain(peerchainSelect, peerCcip);
        CCIPPeer(payable(ccipPeerAddress)).allowlistDestinationChain(peerchainSelect, peerCcip);
        CCIPPeer(payable(ccipPeerAddress)).allowlistTargetTokens(peerchainSelect, peeruniBTC);
        vm.stopBroadcast();
    }

    function initArbPeer() public {
        //TODO modify
        address peerCcip = address(0);
        address peeruniBTC = 0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a;
        uint64 peerchainSelect = 4949039107694359620;
        vm.startBroadcast(owner);
        CCIPPeer(payable(ccipPeerAddress)).allowlistSourceChain(peerchainSelect, peerCcip);
        CCIPPeer(payable(ccipPeerAddress)).allowlistDestinationChain(peerchainSelect, peerCcip);
        CCIPPeer(payable(ccipPeerAddress)).allowlistTargetTokens(peerchainSelect, peeruniBTC);
        vm.stopBroadcast();
    }
}
