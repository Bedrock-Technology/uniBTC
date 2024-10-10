pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {uniBTC} from "../src/mocks/uniBTC.sol";
import {IRouterClient, CCIPLocalSimulator} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {Peer} from "../src/Peer.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

//https://github.com/smartcontractkit/chainlink-local/blob/main/test/smoke/ccip/PingPong.t.sol

contract SmokeTest is Test {
    CCIPLocalSimulator public ccipLocalSimulator;
    uint64 public chainSelector;
    IRouterClient public peerARouter;
    IRouterClient public peerBRouter;
    address public uniBTCProxy;
    Peer public peerA;
    Peer public peerB;
    address public deploy = makeAddr("deploy");
    address public defaultAdmin = makeAddr("defaultAdmin");
    address public defaultMinter = makeAddr("defaultMinter");
    address public peerAuser = makeAddr("peerAuser");
    address public peerBuser = makeAddr("peerBuser");
    address public peerCuser = makeAddr("peerCuser");

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
        Peer peerAImplement = new Peer(_routerA);
        Peer peerBImplement = new Peer(_routerB);
        TransparentUpgradeableProxy peerAProxy = new TransparentUpgradeableProxy(
            address(peerAImplement),
            deploy,
            abi.encodeCall(
                peerAImplement.initialize,
                (defaultAdmin, _uniBTC)
            )
        );
        TransparentUpgradeableProxy peerBProxy = new TransparentUpgradeableProxy(
            address(peerBImplement),
            deploy,
            abi.encodeCall(
                peerBImplement.initialize,
                (defaultAdmin, _uniBTC)
            )
        );
        vm.stopPrank();
        peerA = Peer(payable(peerAProxy));
        peerB = Peer(payable(peerBProxy));
        vm.startPrank(defaultAdmin);
        peerA.allowlistSourceChain(_chainSelector, address(peerB));
        peerA.allowlistDestinationChain(_chainSelector, address(peerB));

        peerB.allowlistSourceChain(_chainSelector, address(peerA));
        peerB.allowlistDestinationChain(_chainSelector, address(peerA));
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
        vm.stopPrank();
        console.logBytes32(messageId);
        assertEq(uniBTC(uniBTCProxy).balanceOf(peerCuser), 300000000);
    }
    //local ccip always return fees = 0
    function test_estimateFees() public {}
}
