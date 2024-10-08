pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TransferProxy} from "../contracts/proxies/TransferProxy.sol";
import "../contracts/Vault.sol";
//forge test --match-contract TransferProxyTest --fork-url https://rpc.ankr.com/bitlayer -vvv
contract TransferProxyTest is Test {
    TransferProxy public transferProxy;
    address payable public vault;
    address public to;
    address public deployer;
    address public owner;
    address public WBTC;

    function setUp() public {
        deployer = makeAddr("deployer");
        vault = payable(0xF9775085d726E782E83585033B58606f7731AB18);
        to = address(0xcb28DAB5e89F6Bf2fEB2de200564bafF77d59957);
        owner = address(0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB);
        WBTC = address(0xfF204e2681A6fA0e2C3FaDe68a1B28fb90E4Fc5F);
        vm.startPrank(deployer);
        transferProxy = new TransferProxy(vault, to);
        vm.stopPrank();
        vm.startPrank(owner);
        address[] memory targets = new address[](1);
        targets[0] = to;
        Vault(vault).allowTarget(targets);
        Vault(vault).grantRole(keccak256("OPERATOR_ROLE"), address(transferProxy));
        vm.stopPrank();
    }

    function test_transfer() public {
        console.log("vault's native token balance:", vault.balance);
        vm.startPrank(deployer);
        transferProxy.transfer(788959378397103396);
        vm.stopPrank();
        assert(to.balance == 788959378397103396);
        console.log("to token balance:", to.balance);
    }

    function test_transferToken() public {
        console.log("vault's WBTC token balance:", IERC20(WBTC).balanceOf(vault));
        vm.startPrank(deployer);
        transferProxy.transfer(WBTC, 169976952130607311);
        vm.stopPrank();
        assert(IERC20(WBTC).balanceOf(to) == 169976952130607311);
        console.log("to token balance:", IERC20(WBTC).balanceOf(to));
    }
}