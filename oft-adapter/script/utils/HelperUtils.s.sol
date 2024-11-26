// SPDX-License-Identifier: MIT
pragma solidity >=0.8.22;

import {stdJson} from "forge-std/StdJson.sol";
import {Vm} from "forge-std/Vm.sol";

library HelperUtils {
    using stdJson for string;

    function getChainName(uint256 chainIdorEid) internal pure returns (string memory) {
        if (chainIdorEid == 17000 || chainIdorEid == 40217) {
            return "ethereumHolesky";
        } else if (chainIdorEid == 11155111 || chainIdorEid == 40161) {
            return "ethereumSepolia";
            //Mainnet
            // } else if (chainIdorEid == 1 || chainIdorEid == 30101) {
            //     return "ethereum";
            // } else if (chainIdorEid == 42161 || chainIdorEid == 30110) {
            //     return "arbitrum";
            // } else if (chainIdorEid == 56 || chainIdorEid == 30102) {
            //     return "bnbchain";
            // } else if (chainIdorEid == 10 || chainIdorEid == 30111) {
            //     return "optimism";
            // } else if (chainIdorEid == 34443 || chainIdorEid == 30260) {
            //     return "mode";
        } else {
            revert("Unsupported chain ID");
        }
    }

    struct NetworkConfig {
        uint32 eid;
        address endPoint;
        address uniBTC;
    }

    function getEthereumHoleskyConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethereumHolesky = NetworkConfig({
            eid: 40217,
            endPoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            uniBTC: 0xE1061F0D0A2AaF273Dc9E2077E8545417B838a8c
        });

        return ethereumHolesky;
    }

    function getEthereumSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethereumSepolia = NetworkConfig({
            eid: 40161,
            endPoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            uniBTC: 0x50fA1411201e2Ac0361FB893E903b80F141b8190
        });

        return ethereumSepolia;
    }

    function getNetworkConfig(uint256 chainId) internal pure returns (NetworkConfig memory) {
        if (chainId == 17000) {
            return getEthereumHoleskyConfig();
        } else if (chainId == 11155111) {
            return getEthereumSepoliaConfig();
            // } else if (chainId == 421614) {
            //     return helperConfig.getArbitrumSepolia();
            // } else if (chainId == 84532) {
            //     return helperConfig.getBaseSepoliaConfig();
            // } else if (chainId == 1) {
            //     return helperConfig.getEthConfig();
            // } else if (chainId == 42161) {
            //     return helperConfig.getArbConfig();
            // } else if (chainId == 56) {
            //     return helperConfig.getBscConfig();
            // } else if (chainId == 10) {
            //     return helperConfig.getOptConfig();
            // } else if (chainId == 34443) {
            //     return helperConfig.getModeConfig();
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
