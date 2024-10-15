// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {CCIPPeer} from "../../src/ccipPeer.sol";
import {uniBTC} from "../../src/mocks/uniBTC.sol";

//simulate
//forge script script/testnet/deploy_bsc.s.sol:DeployCCIPPeer --rpc-url https://bsc-testnet-rpc.publicnode.com

//testnet
//forge script script/testnet/deploy_bsc.s.sol:DeployCCIPPeer --rpc-url https://bsc-testnet-rpc.publicnode.com --account deploy --broadcast

//forge script script/testnet/deploy_bsc.s.sol:DeployCCIPPeer --rpc-url https://bsc-testnet-rpc.publicnode.com --account deploy --broadcast --verify --verifier-url 'https://api-testnet.bscscan.com/api' --etherscan-api-key "xxxxxx" --delay 60

contract DeployCCIPPeer is Script {
    address public deploy;
    address public owner;
    address public router = 0xE1053aE1857476f36A3C62580FF9b016E8EE8F6f;

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
            abi.encodeCall(ccipPeerImplementation.initialize, (owner, address(uniBTCProxy), owner))
        );
        vm.stopPrank();
    }
}

//proxyAdmin
//forge verify-contract 0x20D70277aFC6e1304b89FC1A30D84130f1634510 ../contracts/lib/OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/proxy/transparent/ProxyAdmin.sol:ProxyAdmin \
//--verifier-url 'https://api-testnet.bscscan.com/api' \
//--etherscan-api-key "xxxxxxx" \
//--num-of-optimizations 200 \
//--compiler-version 0.8.19 \
//--constructor-args $(cast abi-encode "constructor()")

//uniBTC Implementation
//forge verify-contract 0xAb3630cEf046e2dFAFd327eB8b7B96D627dEFa83 src/mocks/uniBTC.sol:uniBTC \
//--verifier-url 'https://api-testnet.bscscan.com/api' \
//--etherscan-api-key "xxxxxxx" \
//--num-of-optimizations 200 \
//--compiler-version 0.8.19 \
//--constructor-args $(cast abi-encode "constructor()")
//proxyAddress 0xdF1925B7A0f56a3ED7f74bE2a813Ae8bbA756e59

//ccipPeer Implementation
//forge verify-contract 0xD498e4aEE5585ff8099158E641c025a761ACC656 src/ccipPeer.sol:CCIPPeer \
//--verifier-url 'https://api-testnet.bscscan.com/api' \
//--etherscan-api-key "xxxxxxx" \
//--num-of-optimizations 200 \
//--compiler-version 0.8.19 \
//--constructor-args $(cast abi-encode "constructor(address _router)"0xE1053aE1857476f36A3C62580FF9b016E8EE8F6f)
//proxyAddress 0xbEfC7D6A15cc9bf839E64a16cd43ABD55Dd6633d

//proxyAdmin: 0x6F10dC7dc5ff3Cbb7C18B324AbDC05fADe601370
//uniBTC: 0xF04Cb14F13144505eB93a165476f1259A1538303
//ccipPeer:0x71c1A45eBa172d11c9e52dDF8BADD4b3A585b517
