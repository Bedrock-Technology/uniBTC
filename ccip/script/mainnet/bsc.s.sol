// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {CCIPPeer} from "../../src/ccipPeer.sol";
import {uniBTC} from "../../src/mocks/uniBTC.sol";

//simulate
//forge script script/mainnet/bsc.s.sol:DeployCCIPPeer --rpc-url https://bsc-rpc.publicnode.com --account deploy

//testnet
//forge script script/mainnet/bsc.s.sol:DeployCCIPPeer --rpc-url https://bsc-rpc.publicnode.com --account deploy --broadcast  --verify --verifier-url 'https://api.bscscan.com/api' --etherscan-api-key "xxxxxx" --delay 30

//forge script script/mainnet/bsc.s.sol:DeployCCIPPeer --sig 'initEthPeer()' --rpc-url https://bsc-rpc.publicnode.com --account owner --broadcast

contract DeployCCIPPeer is Script {
    address public deploy;
    address public owner;
    address public router;
    address public proxyAdmin;
    address public uniBTCAddress;
    // TODO modify when contract was deployed.
    address public ccipPeerAddress = address(0);
    address public sysSigner = vm.addr(34);

    function setUp() public {
        deploy = 0x8cb37518330014E027396E3ED59A231FBe3B011A;
        owner = 0xac07f2721EcD955c4370e7388922fA547E922A4f;
        proxyAdmin = 0xb3f925B430C60bA467F7729975D5151c8DE26698;
        uniBTCAddress = 0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a;
        router = 0x34B03Cb9086d7D758AC55af71584F81A598759FE;
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

    function initEthPeer() public {
        //TODO modify
        address etherccipPeer = address(0);
        address etheruniBTC = 0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568;
        uint64 etherchainSelect = 11344663589394136015;
        vm.startBroadcast(owner);
        CCIPPeer(payable(ccipPeerAddress)).allowlistSourceChain(etherchainSelect, etherccipPeer);
        CCIPPeer(payable(ccipPeerAddress)).allowlistDestinationChain(etherchainSelect, etherccipPeer);
        CCIPPeer(payable(ccipPeerAddress)).allowlistTargetTokens(etherchainSelect, etheruniBTC);
        vm.stopBroadcast();
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
