// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {stdJson} from "forge-std/StdJson.sol";
import {Vm} from "forge-std/Vm.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

library HelperUtils {
    using stdJson for string;

    function getChainName(uint256 chainIdorSelector) internal pure returns (string memory) {
        if (chainIdorSelector == 43113 || chainIdorSelector == 14767482510784806043) {
            return "avalancheFuji";
        } else if (chainIdorSelector == 11155111 || chainIdorSelector == 16015286601757825753) {
            return "ethereumSepolia";
        } else if (chainIdorSelector == 421614 || chainIdorSelector == 3478487238524512106) {
            return "arbitrumSepolia";
        } else if (chainIdorSelector == 84532 || chainIdorSelector == 10344971235874465080) {
            return "baseSepolia";
            //Mainnet
        } else if (chainIdorSelector == 1 || chainIdorSelector == 5009297550715157269) {
            return "ethereum";
        } else if (chainIdorSelector == 42161 || chainIdorSelector == 4949039107694359620) {
            return "arbitrum";
        } else if (chainIdorSelector == 56 || chainIdorSelector == 11344663589394136015) {
            return "bnbchain";
        } else if (chainIdorSelector == 10 || chainIdorSelector == 3734403246176062136) {
            return "optimism";
        } else if (chainIdorSelector == 34443 || chainIdorSelector == 7264351850409363825) {
            return "mode";
        } else {
            revert("Unsupported chain ID");
        }
    }

    function getNetworkConfig(HelperConfig helperConfig, uint256 chainId)
        internal
        pure
        returns (HelperConfig.NetworkConfig memory)
    {
        if (chainId == 43113) {
            return helperConfig.getAvalancheFujiConfig();
        } else if (chainId == 11155111) {
            return helperConfig.getEthereumSepoliaConfig();
        } else if (chainId == 421614) {
            return helperConfig.getArbitrumSepolia();
        } else if (chainId == 84532) {
            return helperConfig.getBaseSepoliaConfig();
        } else if (chainId == 1) {
            return helperConfig.getEthConfig();
        } else if (chainId == 42161) {
            return helperConfig.getArbConfig();
        } else if (chainId == 56) {
            return helperConfig.getBscConfig();
        } else if (chainId == 10) {
            return helperConfig.getOptConfig();
        } else if (chainId == 34443) {
            return helperConfig.getModeConfig();
        } else {
            revert("Unsupported chain ID");
        }
    }

    function getAddressFromJson(Vm vm, string memory path, string memory key) internal view returns (address) {
        string memory json = vm.readFile(path);
        return json.readAddress(key);
    }

    function getBoolFromJson(Vm vm, string memory path, string memory key) internal view returns (bool) {
        string memory json = vm.readFile(path);
        return json.readBool(key);
    }

    function getStringFromJson(Vm vm, string memory path, string memory key) internal view returns (string memory) {
        string memory json = vm.readFile(path);
        return json.readString(key);
    }

    function getUintFromJson(Vm vm, string memory path, string memory key) internal view returns (uint256) {
        string memory json = vm.readFile(path);
        return json.readUint(key);
    }

    function bytes32ToHexString(bytes32 _bytes) internal pure returns (string memory) {
        bytes memory hexString = new bytes(64);
        bytes memory hexAlphabet = "0123456789abcdef";
        for (uint256 i = 0; i < 32; i++) {
            hexString[i * 2] = hexAlphabet[uint8(_bytes[i] >> 4)];
            hexString[i * 2 + 1] = hexAlphabet[uint8(_bytes[i] & 0x0f)];
        }
        return string(hexString);
    }

    function uintToStr(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }
}