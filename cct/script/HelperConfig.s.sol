// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {Script} from "forge-std/Script.sol";
import {RateLimiter} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/RateLimiter.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        uint64 chainSelector;
        address router;
        address rmnProxy;
        address tokenAdminRegistry;
        address registryModuleOwnerCustom;
        address tokenAddress;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getEthereumSepoliaConfig();
        } else if (block.chainid == 421614) {
            activeNetworkConfig = getArbitrumSepolia();
        } else if (block.chainid == 43113) {
            activeNetworkConfig = getAvalancheFujiConfig();
        } else if (block.chainid == 84532) {
            activeNetworkConfig = getBaseSepoliaConfig();
            //Mainnet
        } else if (block.chainid == 1) {
            activeNetworkConfig = getEthConfig();
        } else if (block.chainid == 42161) {
            activeNetworkConfig = getArbConfig();
        } else if (block.chainid == 56) {
            activeNetworkConfig = getBscConfig();
        } else if (block.chainid == 10) {
            activeNetworkConfig = getOptConfig();
        } else if (block.chainid == 34443) {
            activeNetworkConfig = getModeConfig();
        } else {
            revert("Unsupported chain ID");
        }
    }

    function getEthereumSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethereumSepoliaConfig = NetworkConfig({
            chainSelector: 16015286601757825753,
            router: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
            rmnProxy: 0xba3f6251de62dED61Ff98590cB2fDf6871FbB991,
            tokenAdminRegistry: 0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82,
            registryModuleOwnerCustom: 0x62e731218d0D47305aba2BE3751E7EE9E5520790,
            tokenAddress: address(0)
        });
        return ethereumSepoliaConfig;
    }

    function getArbitrumSepolia() public pure returns (NetworkConfig memory) {
        NetworkConfig memory arbitrumSepoliaConfig = NetworkConfig({
            chainSelector: 3478487238524512106,
            router: 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165,
            rmnProxy: 0x9527E2d01A3064ef6b50c1Da1C0cC523803BCFF2,
            tokenAdminRegistry: 0x8126bE56454B628a88C17849B9ED99dd5a11Bd2f,
            registryModuleOwnerCustom: 0xE625f0b8b0Ac86946035a7729Aba124c8A64cf69,
            tokenAddress: address(0)
        });
        return arbitrumSepoliaConfig;
    }

    function getAvalancheFujiConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory avalancheFujiConfig = NetworkConfig({
            chainSelector: 14767482510784806043,
            router: 0xF694E193200268f9a4868e4Aa017A0118C9a8177,
            rmnProxy: 0xAc8CFc3762a979628334a0E4C1026244498E821b,
            tokenAdminRegistry: 0xA92053a4a3922084d992fD2835bdBa4caC6877e6,
            registryModuleOwnerCustom: 0x97300785aF1edE1343DB6d90706A35CF14aA3d81,
            tokenAddress: address(0)
        });
        return avalancheFujiConfig;
    }

    function getBaseSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory baseSepoliaConfig = NetworkConfig({
            chainSelector: 10344971235874465080,
            router: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
            rmnProxy: 0x99360767a4705f68CcCb9533195B761648d6d807,
            tokenAdminRegistry: 0x736D0bBb318c1B27Ff686cd19804094E66250e17,
            registryModuleOwnerCustom: 0x8A55C61227f26a3e2f217842eCF20b52007bAaBe,
            tokenAddress: address(0)
        });
        return baseSepoliaConfig;
    }

    function getEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethConfig = NetworkConfig({
            chainSelector: 5009297550715157269,
            router: 0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D,
            rmnProxy: 0x411dE17f12D1A34ecC7F45f49844626267c75e81,
            tokenAdminRegistry: address(0),
            registryModuleOwnerCustom: address(0),
            tokenAddress: 0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568
        });
        return ethConfig;
    }

    function getArbConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory arbConfig = NetworkConfig({
            chainSelector: 4949039107694359620,
            router: 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8,
            rmnProxy: 0xC311a21e6fEf769344EB1515588B9d535662a145,
            tokenAdminRegistry: address(0),
            registryModuleOwnerCustom: address(0),
            tokenAddress: 0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a
        });
        return arbConfig;
    }

    function getBscConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory bscConfig = NetworkConfig({
            chainSelector: 11344663589394136015,
            router: 0x34B03Cb9086d7D758AC55af71584F81A598759FE,
            rmnProxy: 0x9e09697842194f77d315E0907F1Bda77922e8f84,
            tokenAdminRegistry: address(0),
            registryModuleOwnerCustom: address(0),
            tokenAddress: 0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a
        });
        return bscConfig;
    }

    function getOptConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory optConfig = NetworkConfig({
            chainSelector: 3734403246176062136,
            router: 0x3206695CaE29952f4b0c22a169725a865bc8Ce0f,
            rmnProxy: 0x55b3FCa23EdDd28b1f5B4a3C7975f63EFd2d06CE,
            tokenAdminRegistry: address(0),
            registryModuleOwnerCustom: address(0),
            tokenAddress: 0x93919784C523f39CACaa98Ee0a9d96c3F32b593e
        });
        return optConfig;
    }

    function getModeConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory modeConfig = NetworkConfig({
            chainSelector: 7264351850409363825,
            router: 0x24C40f13E77De2aFf37c280BA06c333531589bf1,
            rmnProxy: 0xA0876B45271615c737781185C2B5ada60ed2D2B9,
            tokenAdminRegistry: address(0),
            registryModuleOwnerCustom: address(0),
            tokenAddress: 0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a
        });
        return modeConfig;
    }
}
