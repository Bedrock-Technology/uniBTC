// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {uniBTC} from "../src/mocks/uniBTC.sol";
import {IRouterClient, CCIPLocalSimulator} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {CCIPPeer, IMintableContract} from "../src/CCIPPeer.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

//https://github.com/smartcontractkit/chainlink-local/blob/main/test/smoke/ccip/PingPong.t.sol

contract SmokeTest is Test {
    CCIPLocalSimulator public ccipLocalSimulator;
    uint64 public chainSelector;
    IRouterClient public peerARouter;
    IRouterClient public peerBRouter;
    address public uniBTCProxy;
    CCIPPeer public peerA;
    CCIPPeer public peerB;
    address public deploy = makeAddr("deploy");
    address public defaultAdmin = makeAddr("defaultAdmin");
    address public defaultMinter = makeAddr("defaultMinter");
    address public peerAuser = makeAddr("peerAuser");
    address public peerBuser = makeAddr("peerBuser");
    address public peerCuser = makeAddr("peerCuser");
    uint256 public sysSignKey = 334556765765;

    function deployuniBTC() public {
        vm.startPrank(deploy);
        uniBTC implementation = new uniBTC();
        TransparentUpgradeableProxy uniBTCProxyAddress = new TransparentUpgradeableProxy(
            address(implementation),
            deploy,
            abi.encodeCall(
                implementation.initialize,
                (defaultAdmin, defaultMinter)
            )
        );
        uniBTCProxy = address(uniBTCProxyAddress);
        vm.stopPrank();
    }

    function deployPeers(
        address _routerA,
        address _routerB,
        address _uniBTC,
        uint64 _chainSelector
    ) public {
        vm.startPrank(deploy);
        CCIPPeer peerAImplement = new CCIPPeer(_routerA);
        CCIPPeer peerBImplement = new CCIPPeer(_routerB);
        TransparentUpgradeableProxy peerAProxy = new TransparentUpgradeableProxy(
            address(peerAImplement),
            deploy,
            abi.encodeCall(
                peerAImplement.initialize,
                (defaultAdmin, _uniBTC, vm.addr(sysSignKey))
            )
        );
        TransparentUpgradeableProxy peerBProxy = new TransparentUpgradeableProxy(
            address(peerBImplement),
            deploy,
            abi.encodeCall(
                peerBImplement.initialize,
                (defaultAdmin, _uniBTC, vm.addr(sysSignKey))
            )
        );
        vm.stopPrank();
        peerA = CCIPPeer(payable(peerAProxy));
        peerB = CCIPPeer(payable(peerBProxy));
        vm.startPrank(defaultAdmin);
        peerA.allowlistSourceChain(_chainSelector, address(peerB));
        peerA.allowlistDestinationChain(_chainSelector, address(peerB));
        peerA.allowlistTargetTokens(_chainSelector, uniBTCProxy);

        peerB.allowlistSourceChain(_chainSelector, address(peerA));
        peerB.allowlistDestinationChain(_chainSelector, address(peerA));
        peerB.allowlistTargetTokens(_chainSelector, uniBTCProxy);

        vm.stopPrank();
    }

    function setUp() public {
        //vm.deal(deploy, 10 ether);
        deployuniBTC();
        ccipLocalSimulator = new CCIPLocalSimulator();
        (
            uint64 chainSelector_,
            IRouterClient sourceRouter,
            IRouterClient destinationRouter,
            ,
            ,
            ,

        ) = ccipLocalSimulator.configuration();
        peerARouter = sourceRouter;
        peerBRouter = destinationRouter;
        chainSelector = chainSelector_;

        vm.startPrank(defaultMinter);
        uniBTC(uniBTCProxy).mint(
            defaultMinter,
            12 * 10 ** uniBTC(uniBTCProxy).decimals()
        );
        uniBTC(uniBTCProxy).transfer(peerBuser, 600000000);
        uniBTC(uniBTCProxy).transfer(peerAuser, 600000000);
        vm.stopPrank();
        assertEq(uniBTC(uniBTCProxy).balanceOf(peerBuser), 600000000);
        deployPeers(
            address(peerARouter),
            address(peerBRouter),
            uniBTCProxy,
            chainSelector
        );
        vm.startPrank(defaultAdmin);
        uniBTC(uniBTCProxy).grantRole(
            uniBTC(uniBTCProxy).MINTER_ROLE(),
            address(peerA)
        );
        uniBTC(uniBTCProxy).grantRole(
            uniBTC(uniBTCProxy).MINTER_ROLE(),
            address(peerB)
        );
        vm.stopPrank();
    }

    function test_baseCase() public {
        vm.startPrank(peerAuser);
        uniBTC(uniBTCProxy).approve(address(peerA), 600000000);
        bytes32 messageId = peerA.sendToken(
            chainSelector,
            peerCuser,
            300000000
        );
        assertTrue(peerB.processedMessages(messageId), "not true");
        vm.stopPrank();
        console.logBytes32(messageId);
        assertEq(uniBTC(uniBTCProxy).balanceOf(peerCuser), 300000000);
        assertEq(uniBTC(uniBTCProxy).balanceOf(peerAuser), 300000000);
    }

    function test_paused_A() public {
        vm.startPrank(defaultAdmin);
        peerA.pause();
        vm.stopPrank();

        vm.startPrank(peerAuser);
        uniBTC(uniBTCProxy).approve(address(peerA), 600000000);
        vm.expectRevert();
        peerA.sendToken(chainSelector, peerCuser, 300000000);
        vm.stopPrank();
    }

    function test_paused_B() public {
        vm.startPrank(defaultAdmin);
        peerB.pause();
        vm.stopPrank();

        vm.startPrank(peerAuser);
        uniBTC(uniBTCProxy).approve(address(peerA), 600000000);
        vm.expectRevert();
        peerA.sendToken(chainSelector, peerCuser, 300000000);
        vm.stopPrank();
    }

    function test_destination_not_allowed() public {
        vm.startPrank(defaultAdmin);
        peerA.allowlistDestinationChain(chainSelector, address(0));
        vm.stopPrank();

        vm.startPrank(peerAuser);
        uniBTC(uniBTCProxy).approve(address(peerA), 600000000);
        vm.expectRevert();
        peerA.sendToken(chainSelector, peerCuser, 300000000);
        vm.stopPrank();
    }

    function test_src_not_allowed() public {
        vm.startPrank(defaultAdmin);
        peerB.allowlistSourceChain(chainSelector, address(0));
        vm.stopPrank();

        vm.startPrank(peerAuser);
        uniBTC(uniBTCProxy).approve(address(peerA), 600000000);
        vm.expectRevert();
        peerA.sendToken(chainSelector, peerCuser, 300000000);
        vm.stopPrank();
    }

    function test_token_not_allowed() public {
        vm.startPrank(defaultAdmin);
        peerA.allowlistTargetTokens(chainSelector, address(0));
        vm.stopPrank();

        vm.startPrank(peerAuser);
        uniBTC(uniBTCProxy).approve(address(peerA), 600000000);
        vm.expectRevert();
        peerA.sendToken(chainSelector, peerCuser, 300000000);
        vm.stopPrank();
    }

    function test_minAmt() public {
        vm.startPrank(defaultAdmin);
        peerA.setMinTransferAmt(900000000);
        vm.stopPrank();

        vm.startPrank(peerAuser);
        uniBTC(uniBTCProxy).approve(address(peerA), 600000000);
        vm.expectRevert();
        peerA.sendToken(chainSelector, peerCuser, 300000000);
        vm.stopPrank();
    }

    function test_minApprove() public {
        vm.startPrank(peerAuser);
        uniBTC(uniBTCProxy).approve(address(peerA), 100000000);
        vm.expectRevert();
        peerA.sendToken(chainSelector, peerCuser, 300000000);
        vm.stopPrank();
    }

    function test_sendSign() public {
        vm.startPrank(peerAuser);
        uniBTC(uniBTCProxy).approve(address(peerA), 600000000);
        bytes32 digest = sha256(
            abi.encode(
                peerAuser,
                address(peerA),
                block.chainid,
                chainSelector,
                peerCuser,
                300000000
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sysSignKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        bytes32 messageId = peerA.sendToken(
            chainSelector,
            peerCuser,
            300000000,
            signature
        );
        console.logBytes32(messageId);
        assertEq(uniBTC(uniBTCProxy).balanceOf(peerCuser), 300000000);
        assertEq(uniBTC(uniBTCProxy).balanceOf(peerAuser), 300000000);
    }

    function test_verifySignChange() public {
        bytes32 digest = sha256(
            abi.encode(
                defaultAdmin,
                address(peerA),
                block.chainid,
                chainSelector,
                peerCuser,
                300000000
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sysSignKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        bool verify = peerA.verifySendTokenSign(
            defaultAdmin,
            chainSelector,
            peerCuser,
            300000000,
            signature
        );
        assert(verify == true);

        //change
        uint256 newSysSigner = 324325435;
        address newSysSignerAddress = vm.addr(newSysSigner);
        vm.startPrank(defaultAdmin);
        peerA.setSysSinger(newSysSignerAddress);
        vm.stopPrank();
        bytes32 digest1 = sha256(
            abi.encode(
                defaultAdmin,
                address(peerA),
                block.chainid,
                chainSelector,
                peerCuser,
                300000000
            )
        );
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(newSysSigner, digest1);
        bytes memory signature1 = abi.encodePacked(r1, s1, v1);
        bool verify1 = peerA.verifySendTokenSign(
            defaultAdmin,
            chainSelector,
            peerCuser,
            300000000,
            signature1
        );
        assert(verify1 == true);
    }

    function test_targetCall() public {
        vm.startPrank(defaultAdmin);
        bytes memory callData = abi.encodeWithSelector(IMintableContract.mint.selector, peerCuser, 300000000);
        bytes32 messageId = peerA.targetCall(chainSelector, peerB.uniBTC(), callData);
        assertTrue(peerB.processedMessages(messageId), "not true");
        vm.stopPrank();
        console.logBytes32(messageId);
        assertEq(uniBTC(uniBTCProxy).balanceOf(peerCuser), 300000000);
        assertEq(uniBTC(uniBTCProxy).balanceOf(peerAuser), 600000000);
    }
}
