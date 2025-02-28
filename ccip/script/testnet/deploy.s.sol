// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {CCIPPeer} from "../../src/ccipPeer.sol";
import {uniBTC} from "../../src/mocks/uniBTC.sol";

contract DeployCCIPPeer is Script {
    function deploy(address owner, address router, address signer) public {
        vm.startBroadcast();
        //deploy proxyAdmin
        ProxyAdmin adminInstance = new ProxyAdmin();
        adminInstance.transferOwnership(owner);
        console.log("proxyAdmin:", address(adminInstance));
        //deploy mockUniBTC
        uniBTC uniBTCImplementation = new uniBTC();
        TransparentUpgradeableProxy uniBTCProxy = new TransparentUpgradeableProxy(
            address(uniBTCImplementation),
            address(adminInstance),
            abi.encodeCall(uniBTCImplementation.initialize, (owner, owner))
        );
        console.log("uniBTC:", address(uniBTCProxy));
        //deploy ccipPeer
        CCIPPeer ccipPeerImplementation = new CCIPPeer(router);
        TransparentUpgradeableProxy ccipPeerProxy = new TransparentUpgradeableProxy(
            address(ccipPeerImplementation),
            address(adminInstance),
            abi.encodeCall(ccipPeerImplementation.initialize, (owner, address(uniBTCProxy), signer))
        );
        console.log("ccipPeer:", address(ccipPeerProxy));
        uniBTC(address(uniBTCProxy)).grantRole(uniBTC(address(uniBTCProxy)).MINTER_ROLE(), address(ccipPeerProxy));
        vm.stopBroadcast();
    }

    function setPeer(address ccipPeer, address peerccipPeer, address peerUniBTC, uint64 peerChainSelector) public {
        vm.startBroadcast();
        CCIPPeer(payable(ccipPeer)).allowlistSourceChain(peerChainSelector, peerccipPeer);
        CCIPPeer(payable(ccipPeer)).allowlistDestinationChain(peerChainSelector, peerccipPeer);
        CCIPPeer(payable(ccipPeer)).allowlistTargetTokens(peerChainSelector, peerUniBTC);
        vm.stopBroadcast();
    }

    function upgrade(
        address proxyAdmin,
        address ccipPeer,
        address owner,
        address router,
        address uniBTCAddress,
        address signer
    ) public {
        vm.startBroadcast();
        ProxyAdmin proxyAdminIns = ProxyAdmin(proxyAdmin);
        ITransparentUpgradeableProxy ccipPeerProxy = ITransparentUpgradeableProxy(ccipPeer);
        CCIPPeer ccipPeerIns = new CCIPPeer(router);
        proxyAdminIns.upgradeAndCall(
            ccipPeerProxy, address(ccipPeerIns), abi.encodeCall(ccipPeerIns.initialize, (owner, uniBTCAddress, signer))
        );
        vm.stopBroadcast();
    }

    function sendToken(
        address _ccipPeerAddr,
        uint64 _destinationChainSelector,
        address _recipient,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) public {
        CCIPPeer ccipPeerIns = CCIPPeer(payable(_ccipPeerAddr));
        uniBTC uniBTCIns = uniBTC(ccipPeerIns.uniBTC());

        vm.startBroadcast();
        uint256 allowance = uniBTCIns.allowance(msg.sender, _ccipPeerAddr);
        console.log("allowance:", allowance);
        if (allowance < _amount) {
            uniBTCIns.approve(_ccipPeerAddr, 10 * _amount);
        }
        uint256 fees = ccipPeerIns.estimateSendTokenFees(_destinationChainSelector, _recipient, _amount);
        console.log("est fees:%d", fees);
        // send to owner, 1uniBTC
        ccipPeerIns.sendToken{value: fees}(_destinationChainSelector, _recipient, _amount, _nonce, _signature);
        vm.stopBroadcast();
    }
}
// forge script script/testnet/deploy.s.sol:DeployCCIPPeer --sig 'deploy(address,address,address)' $OWNER_ADDRESS 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59 $SIGNER_ADDRESS \
// --rpc-url $RPC_ETH_SEPOLIA --account $DEPLOYER --broadcast \
// --verify --verifier-url $RPC_ETH_SEPOLIA_SCAN --etherscan-api-key $KEY_ETH_SEPOLIA_SCAN --delay 30
// proxyAdmin:0xA99248E4F1ECD23d35ED9132f80cbC956f6BB373
// uniBTC:0x3C6E4408f20bf2E54541A231e28160280C7B83dd
// ccipPeer:0xBF31972992AB3dEA880fDd9877973d66d8aE1b64

// set peer arb sepolia
// forge script script/testnet/deploy.s.sol:DeployCCIPPeer --sig 'setPeer(address,address,address,uint64)' 0xBF31972992AB3dEA880fDd9877973d66d8aE1b64 0xbEfC7D6A15cc9bf839E64a16cd43ABD55Dd6633d 0xdF1925B7A0f56a3ED7f74bE2a813Ae8bbA756e59 3478487238524512106 \
// --rpc-url $RPC_ETH_SEPOLIA --account $OWNER --broadcast

// sign
// forge script script/mainnet/digest.s.sol:Digest --sig 'sign(address,address,uint256,uint256,address,uint256,uint256)' \
// $OWNER_ADDRESS \
// 0xBF31972992AB3dEA880fDd9877973d66d8aE1b64 \
// 11155111 \
// 3478487238524512106 \
// $OWNER_ADDRESS \
// 1000000000 \
// $RANDOM \
// --account $SIGNER

// forge script script/testnet/deploy.s.sol:DeployCCIPPeer --sig 'sendToken(address,uint64,address,uint256,uint256,bytes)' \
// 0xBF31972992AB3dEA880fDd9877973d66d8aE1b64 \
// 3478487238524512106 \
// $OWNER_ADDRESS \
// 1000000000 \
// 26964 \
// 0xfd93eaf2359ed34ef1d355b548a0e4597c89dc25af3f65141e82e4d8e3fbae077b66738b833d37a0c8ec85a69c0b723f434872ca04692838ef5471aff8387fdb1b \
// --rpc-url $RPC_ETH_SEPOLIA --sender $OWNER_ADDRESS --account $OWNER --broadcast
// hash:0x6374842e36de220d129be5f539505fca50d5867035f6fb4d9ceb28d9ca287a0f

// forge script script/testnet/deploy.s.sol:DeployCCIPPeer --sig 'upgrade(address,address,address,address,address,address)' \
// 0xA99248E4F1ECD23d35ED9132f80cbC956f6BB373 \
// 0xBF31972992AB3dEA880fDd9877973d66d8aE1b64 \
// $OWNER_ADDRESS \
// 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59 \
// 0x3C6E4408f20bf2E54541A231e28160280C7B83dd \
// $SIGNER_ADDRESS \
// --rpc-url $RPC_ETH_SEPOLIA --sender $OWNER_ADDRESS --account $OWNER --broadcast \
// --verify --verifier-url $RPC_ETH_SEPOLIA_SCAN --etherscan-api-key $KEY_ETH_SEPOLIA_SCAN --delay 30

// forge script script/testnet/deploy.s.sol:DeployCCIPPeer --sig 'sendToken(address,uint64,address,uint256,uint256,bytes)' \
// 0xBF31972992AB3dEA880fDd9877973d66d8aE1b64 \
// 3478487238524512106 \
// $OWNER_ADDRESS \
// 100000 \
// 342 \
// 0x0a38f4fac9ab6a73a388bbae283cea7946d09b45c5e947a69f399988fb0de091490981afd5f433cc3b496993cc3a0f09b25e65f6bec1892a31252adc4d2e1d911b \
// --rpc-url $RPC_ETH_SEPOLIA --sender $OWNER_ADDRESS --account $OWNER --broadcast

//**************************************** */

// forge script script/testnet/deploy.s.sol:DeployCCIPPeer --sig 'deploy(address,address,address)' $OWNER_ADDRESS 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165 $SIGNER_ADDRESS \
// --rpc-url $RPC_ARB_SEPOLIA --account $DEPLOYER --broadcast \
// --verify --verifier-url $RPC_ARB_SEPOLIA_SCAN --etherscan-api-key $KEY_ARB_SEPOLIA_SCAN --delay 30
// proxyAdmin:0x20D70277aFC6e1304b89FC1A30D84130f1634510
// uniBTC:0xdF1925B7A0f56a3ED7f74bE2a813Ae8bbA756e59
// ccipPeer:0xbEfC7D6A15cc9bf839E64a16cd43ABD55Dd6633d

// set peer sepolia
// forge script script/testnet/deploy.s.sol:DeployCCIPPeer --sig 'setPeer(address,address,address,uint64)' 0xbEfC7D6A15cc9bf839E64a16cd43ABD55Dd6633d 0xBF31972992AB3dEA880fDd9877973d66d8aE1b64 0x3C6E4408f20bf2E54541A231e28160280C7B83dd 16015286601757825753 \
// --rpc-url $RPC_ARB_SEPOLIA --account $OWNER --broadcast

// sign
// forge script script/mainnet/digest.s.sol:Digest --sig 'sign(address,address,uint256,uint256,address,uint256,uint256)' \
// $OWNER_ADDRESS \
// 0xbEfC7D6A15cc9bf839E64a16cd43ABD55Dd6633d \
// 421614 \
// 16015286601757825753 \
// $OWNER_ADDRESS \
// 1000000000 \
// $RANDOM \
// --account $SIGNER

// forge script script/testnet/deploy.s.sol:DeployCCIPPeer --sig 'sendToken(address,uint64,address,uint256,uint256,bytes)' \
// 0xbEfC7D6A15cc9bf839E64a16cd43ABD55Dd6633d \
// 16015286601757825753 \
// $OWNER_ADDRESS \
// 1000000000 \
// 4398 \
// 0x6ed9e49c524bfbda9542b210e9f3a38c50d4560db16ee0b6530449be2b4d418131b317091695319bec51f8cc4670f5acdba13ff7a5969141e67b46e425d077c41c \
// --rpc-url $RPC_ARB_SEPOLIA --sender $OWNER_ADDRESS --account $OWNER --broadcast
// 0xf6ad4fc24b81e37332a2e05117875d56c618445c23ca1bb3e2d20e7f39eda036

// forge script script/testnet/deploy.s.sol:DeployCCIPPeer --sig 'upgrade(address,address,address,address,address,address)' \
// 0x20D70277aFC6e1304b89FC1A30D84130f1634510 \
// 0xbEfC7D6A15cc9bf839E64a16cd43ABD55Dd6633d \
// $OWNER_ADDRESS \
// 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165 \
// 0xdF1925B7A0f56a3ED7f74bE2a813Ae8bbA756e59 \
// $SIGNER_ADDRESS \
// --rpc-url $RPC_ARB_SEPOLIA --sender $OWNER_ADDRESS --account $OWNER --broadcast \
// --verify --verifier-url $RPC_ARB_SEPOLIA_SCAN --etherscan-api-key $KEY_ARB_SEPOLIA_SCAN --delay 30

// forge script script/testnet/deploy.s.sol:DeployCCIPPeer --sig 'sendToken(address,uint64,address,uint256,uint256,bytes)' \
// 0xbEfC7D6A15cc9bf839E64a16cd43ABD55Dd6633d \
// 16015286601757825753 \
// $OWNER_ADDRESS \
// 100000 \
// 342 \
// 0x8fa7fe7d2f89986dcea33734b5d2e403ccb754ac0754b831d56cc4d119a3a0d528cecfb5cfb608794f2b777d5a2be6166680aa16f0666dfedda6fa39e3637e221b \
// --rpc-url $RPC_ARB_SEPOLIA --sender $OWNER_ADDRESS --account $OWNER --broadcast
