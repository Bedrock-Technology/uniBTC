// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {CCIPPeer} from "../../src/ccipPeer.sol";
import {uniBTC} from "../../src/mocks/uniBTC.sol";
//simulate
//forge script script/testnet/deploy_fuji.s.sol:DeployCCIPPeer --rpc-url https://avalanche-fuji-c-chain-rpc.publicnode.com

//testnet
//forge script script/testnet/deploy_fuji.s.sol:DeployCCIPPeer --rpc-url https://avalanche-fuji-c-chain-rpc.publicnode.com --account deploy --broadcast \
//--verify --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' --etherscan-api-key "verifyContract"

contract DeployCCIPPeer is Script {
    address public deploy;
    address public owner;
    address public router = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;

    function setUp() public {
        deploy = 0x8cb37518330014E027396E3ED59A231FBe3B011A;
        owner = 0xac07f2721EcD955c4370e7388922fA547E922A4f;
    }

    function run() public {
        vm.startBroadcast(deploy);
        //deploy proxyAdmin
        ProxyAdmin adminInstance = new ProxyAdmin();
        adminInstance.transferOwnership(owner);
        //deploy mockUniBTC
        uniBTC uniBTCImplementation = new uniBTC();
        TransparentUpgradeableProxy uniBTCProxy = new TransparentUpgradeableProxy(
                address(uniBTCImplementation),
                address(adminInstance),
                abi.encodeCall(uniBTCImplementation.initialize, (owner, owner))
            );
        //deploy ccipPeer
        CCIPPeer ccipPeerImplementation = new CCIPPeer(router);
        new TransparentUpgradeableProxy(
            address(ccipPeerImplementation),
            address(adminInstance),
            abi.encodeCall(
                ccipPeerImplementation.initialize,
                (owner, address(uniBTCProxy), owner)
            )
        );
        vm.stopPrank();
    }
}

//proxyAdmin
//forge verify-contract 0xE1061F0D0A2AaF273Dc9E2077E8545417B838a8c ../contracts/lib/OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/proxy/transparent/ProxyAdmin.sol:ProxyAdmin \
//--verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' \
//--etherscan-api-key "verifyContract" \
//--num-of-optimizations 200 \
//--compiler-version 0.8.19 \
//--constructor-args $(cast abi-encode "constructor()")

//uniBTC Implementation
//forge verify-contract 0xd8B81B8950981EFbA4c00Eed567f903580A6649c src/mocks/uniBTC.sol:uniBTC \
//--verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' \
//--etherscan-api-key "verifyContract" \
//--num-of-optimizations 200 \
//--compiler-version 0.8.19 \
//--constructor-args $(cast abi-encode "constructor()")
//proxyAddress 0xAb3630cEf046e2dFAFd327eB8b7B96D627dEFa83

//ccipPeer Implementation
//forge verify-contract 0xdF1925B7A0f56a3ED7f74bE2a813Ae8bbA756e59 src/ccipPeer.sol:CCIPPeer \
//--verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' \
//--etherscan-api-key "verifyContract" \
//--num-of-optimizations 200 \
//--compiler-version 0.8.19 \
//--constructor-args $(cast abi-encode "constructor(address _router)" 0xF694E193200268f9a4868e4Aa017A0118C9a8177)
//proxyAddress 0xD498e4aEE5585ff8099158E641c025a761ACC656

