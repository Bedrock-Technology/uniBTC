pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MBTCProxy, ILockNativeTokenWithBridgeFee} from "../contracts/proxies/MBTCProxy.sol";
import {Vault} from "../contracts/Vault.sol";
//forge test --match-contract MBTCProxyTest --fork-url https://rpc.merlinchain.io -vvvv
contract MBTCProxyTest is Test, ILockNativeTokenWithBridgeFee {
    MBTCProxy public mbtcProxy;
    address payable public vault;
    address public bridge;
    address public deployer;
    address public owner;
    address public mBTC;
    address public mTokenSwap;
    string public constant l1Address = "bc1qma2epmz00c7kutshs0h7m8rra8ceekht87amu7";

    function setUp() public {
        deployer = makeAddr("deployer");
        vault = payable(0xF9775085d726E782E83585033B58606f7731AB18);
        mBTC = address(0xB880fd278198bd590252621d4CD071b1842E9Bcd);
        mTokenSwap = address(0x72A817715f174a32303e8C33cDCd25E0dACfE60b);
        bridge = address(0x28AD6b7dfD79153659cb44C2155cf7C0e1CeEccC);
        owner = address(0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB);
        vm.startPrank(deployer);
        mbtcProxy = new MBTCProxy(vault, mBTC, mTokenSwap);
        vm.stopPrank();
        vm.startPrank(owner);
        address[] memory targets = new address[](1);
        targets[0] = bridge;
        Vault(vault).allowTarget(targets);
        Vault(vault).grantRole(keccak256("OPERATOR_ROLE"), address(mbtcProxy));
        vm.stopPrank();
        deal(vault, 2 ether);
    }

    function test_swapL2BTCToL1BTC() public {
        console.log("vault's native token balance:", vault.balance);
        vm.startPrank(deployer);
        uint256 fee = mbtcProxy.getBridgeFee();
        uint256 baseAmount = 1 ether; //1BTC
        vm.expectEmit(true, true, true, true, bridge);
        emit LockNativeTokenWithBridgeFee(vault, 1 ether, l1Address, fee);
        mbtcProxy.swapL2BTCToL1BTC(baseAmount + fee, l1Address);
        vm.stopPrank();
        assert(vault.balance == 1 ether - fee);
        console.log("vault's native token balance:", vault.balance);
    }

    function test_nextHash() public view {
        bytes32 BASE_HASH = 0xbeD0000000000000000000000000000000000000000000000000000000000000;
        uint256 nonce = 18;
        bytes32 txHash = BASE_HASH | bytes32(nonce);
        console.logBytes32(txHash);
    }
}