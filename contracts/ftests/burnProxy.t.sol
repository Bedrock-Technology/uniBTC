// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BurnProxy} from "../contracts/proxies/BurnProxy.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IAccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import {Vault} from "../contracts/Vault.sol";
//forge test --match-contract BurnProxyTest --fork-url https://eth.llamarpc.com -vvvv

contract BurnProxyTest is Test {
    BurnProxy public burnProxy;
    address payable public vault;
    address public token;
    address public deployer;

    function setUp() public {
        deployer = makeAddr("deployer");
        vault = payable(0x047D41F2544B7F63A8e991aF2068a363d210d6Da);
        token = address(0xA700992A9815d3bfECEDfE51B030fD294Bc0b090);

        vm.startPrank(deployer);
        burnProxy = new BurnProxy(vault, token);
        vm.stopPrank();

        address owner = address(0xC9dA980fFABbE2bbe15d4734FDae5761B86b5Fc3);
        vm.startPrank(owner);
        address[] memory targets = new address[](1);
        targets[0] = token;
        Vault(vault).allowTarget(targets);
        Vault(vault).grantRole(keccak256("OPERATOR_ROLE"), address(burnProxy));
        vm.stopPrank();

        address tokenOwner = address(0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB);
        vm.startPrank(tokenOwner);
        IAccessControlUpgradeable(token).grantRole(keccak256("MINTER_ROLE"), address(vault));
        vm.stopPrank();
    }

    function test_burn() public {
        uint256 _beforeBalance = IERC20Upgradeable(token).balanceOf(vault);
        console.log("vault's token balance:", _beforeBalance);

        vm.startPrank(deployer);
        burnProxy.burn(_beforeBalance);
        vm.stopPrank();

        uint256 _afterBalance = IERC20Upgradeable(token).balanceOf(vault);

        assert(_afterBalance == 0);
        console.log("token token balance:", _afterBalance);
    }
}
