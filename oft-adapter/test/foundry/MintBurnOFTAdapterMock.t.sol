// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Mock imports
import { OFTMock } from "../mocks/OFTMock.sol";
import { MintBurnOFTAdapterMock } from "../mocks/MintBurnOFTAdapterMock.sol";
import { ElevatedMinterBurner, IMintableBurnable } from "../mocks/ElevatedMinterBurnerMock.sol";
import { OFTComposerMock } from "../mocks/OFTComposerMock.sol";

import { MintBurnERC20Mock } from "../mocks/MintBurnERC20Mock.sol";

// OApp imports
import { IOAppOptionsType3, EnforcedOptionParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OAppOptionsType3.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

// OFT imports
import { IOFT, SendParam, OFTReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import { MessagingFee, MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import { OFTMsgCodec } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import { OFTComposeMsgCodec } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";

// OZ imports
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Forge imports
import "forge-std/console.sol";

// DevTools imports
import { TestHelperOz5 } from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

contract MyMintBurnOFTAdapterMockTest is TestHelperOz5 {

    using OptionsBuilder for bytes;

    uint32 aEid = 1;
    uint32 bEid = 2;
    uint32 cEid = 3;

    MintBurnERC20Mock aERC20; // assumes already deployed
    ElevatedMinterBurner aMinterBurner;
    MintBurnOFTAdapterMock aOFTAdapter;

    OFTMock bOFT;

    MintBurnERC20Mock cERC20; // assumes already deployed
    ElevatedMinterBurner cMinterBurner;
    MintBurnOFTAdapterMock cOFTAdapter;

    address public userA = address(0x1);
    address public userB = address(0x2);
    address public userC = address(0x3);
    
    address public attacker = address(0x4);

    uint256 public initialBalance = 100 ether;

    error NotAllowedOperator();

    function setUp() public virtual override {
        vm.deal(userA, 1000 ether);
        vm.deal(userB, 1000 ether);
        vm.deal(userC, 1000 ether);

        super.setUp();
        setUpEndpoints(3, LibraryType.UltraLightNode);

        aERC20 = new MintBurnERC20Mock("aMB", "aMB");
        cERC20 = new MintBurnERC20Mock("cMB", "cMB");

        aMinterBurner = new ElevatedMinterBurner(IMintableBurnable(aERC20), address(this));
        cMinterBurner = new ElevatedMinterBurner(IMintableBurnable(cERC20), address(this));

        aOFTAdapter = MintBurnOFTAdapterMock(
            _deployOApp(type(MintBurnOFTAdapterMock).creationCode, abi.encode(IMintableBurnable(aERC20), address(aMinterBurner), address(endpoints[aEid]), address(this)))
        );

        bOFT = OFTMock(
            _deployOApp(type(OFTMock).creationCode, abi.encode("bOFT", "bOFT", address(endpoints[bEid]), address(this)))
        );

        cOFTAdapter = MintBurnOFTAdapterMock(
            _deployOApp(type(MintBurnOFTAdapterMock).creationCode, abi.encode(IMintableBurnable(cERC20), address(cMinterBurner), address(endpoints[cEid]), address(this)))
        );

        // set oft adapter as operator of minter burner
        aMinterBurner.setOperator(address(aOFTAdapter), true);
        cMinterBurner.setOperator(address(cOFTAdapter), true);

        // config and wire the ofts
        address[] memory ofts = new address[](3);
        ofts[0] = address(aOFTAdapter);
        ofts[1] = address(bOFT);
        ofts[2] = address(cOFTAdapter);
        this.wireOApps(ofts);

        // mint tokens
        aMinterBurner.mint(userA, initialBalance);
        bOFT.mint(userB, initialBalance);
        cMinterBurner.mint(userC, initialBalance);
    }

    function test_constructor() public {
        assertEq(aOFTAdapter.owner(), address(this));
        assertEq(bOFT.owner(), address(this));
        assertEq(cOFTAdapter.owner(), address(this));

        assertEq(aERC20.balanceOf(userA), initialBalance);
        assertEq(bOFT.balanceOf(userB), initialBalance);
        assertEq(cERC20.balanceOf(userC), initialBalance);

        assertEq(aOFTAdapter.token(), address(aERC20));
        assertEq(bOFT.token(), address(bOFT));
        assertEq(cOFTAdapter.token(), address(cERC20));
    }

    function test_set_operator() public {
        vm.prank(attacker);
        vm.expectRevert();
        aMinterBurner.setOperator(address(aOFTAdapter), true);
    }

    function test_mint_operator() public {
        vm.prank(attacker);
        vm.expectRevert();
        aMinterBurner.mint(attacker, initialBalance);
    }

    function test_burn_operator() public {
        vm.prank(attacker);
        vm.expectRevert();
        aMinterBurner.burn(attacker, initialBalance);
    }

    function test_send_adapter_to_oft() public {
        uint256 tokensToSend = 1 ether;
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        SendParam memory sendParam = SendParam(
            bEid,
            addressToBytes32(userB),
            tokensToSend,
            tokensToSend,
            options,
            "",
            ""
        );
        MessagingFee memory fee = aOFTAdapter.quoteSend(sendParam, false);

        assertEq(aERC20.balanceOf(userA), initialBalance);
        assertEq(bOFT.balanceOf(userB), initialBalance);

        vm.startPrank(userA);
        aOFTAdapter.send{ value: fee.nativeFee }(sendParam, fee, payable(address(this)));
        vm.stopPrank();
        verifyPackets(bEid, addressToBytes32(address(bOFT)));

        assertEq(aERC20.balanceOf(userA), initialBalance - tokensToSend);
        assertEq(bOFT.balanceOf(userB), initialBalance + tokensToSend);
    }

    function test_send_adapter_to_adapter() public {
        uint256 tokensToSend = 1 ether;
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        SendParam memory sendParam = SendParam(
            cEid,
            addressToBytes32(userC),
            tokensToSend,
            tokensToSend,
            options,
            "",
            ""
        );
        MessagingFee memory fee = aOFTAdapter.quoteSend(sendParam, false);

        assertEq(aERC20.balanceOf(userA), initialBalance);
        assertEq(cERC20.balanceOf(userC), initialBalance);

        vm.startPrank(userA);
        aOFTAdapter.send{ value: fee.nativeFee }(sendParam, fee, payable(address(this)));
        vm.stopPrank();
        verifyPackets(cEid, addressToBytes32(address(cOFTAdapter)));

        assertEq(aERC20.balanceOf(userA), initialBalance - tokensToSend);
        assertEq(cERC20.balanceOf(userC), initialBalance + tokensToSend);
    }

    function test_send_oft_adapter_compose_msg_to_oft() public {
        uint256 tokensToSend = 1 ether;

        OFTComposerMock composer = new OFTComposerMock();

        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(200000, 0)
            .addExecutorLzComposeOption(0, 500000, 0);
        bytes memory composeMsg = hex"1234";
        SendParam memory sendParam = SendParam(
            bEid,
            addressToBytes32(address(composer)),
            tokensToSend,
            tokensToSend,
            options,
            composeMsg,
            ""
        );
        MessagingFee memory fee = aOFTAdapter.quoteSend(sendParam, false);

        assertEq(aERC20.balanceOf(userA), initialBalance);
        assertEq(bOFT.balanceOf(address(composer)), 0);

        vm.prank(userA);
        (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) = aOFTAdapter.send{ value: fee.nativeFee }(
            sendParam,
            fee,
            payable(address(this))
        );
        verifyPackets(bEid, addressToBytes32(address(bOFT)));

        // lzCompose params
        uint32 dstEid_ = bEid;
        address from_ = address(bOFT);
        bytes memory options_ = options;
        bytes32 guid_ = msgReceipt.guid;
        address to_ = address(composer);
        bytes memory composerMsg_ = OFTComposeMsgCodec.encode(
            msgReceipt.nonce,
            aEid,
            oftReceipt.amountReceivedLD,
            abi.encodePacked(addressToBytes32(userA), composeMsg)
        );
        this.lzCompose(dstEid_, from_, options_, guid_, to_, composerMsg_);

        assertEq(aERC20.balanceOf(userA), initialBalance - tokensToSend);
        assertEq(bOFT.balanceOf(address(composer)), tokensToSend);

        assertEq(composer.from(), from_);
        assertEq(composer.guid(), guid_);
        assertEq(composer.message(), composerMsg_);
        assertEq(composer.executor(), address(this));
        assertEq(composer.extraData(), composerMsg_); // default to setting the extraData to the message as well to test
    }

    function test_send_oft_adapter_compose_msg_to_oft_adapter() public {
        uint256 tokensToSend = 1 ether;

        OFTComposerMock composer = new OFTComposerMock();

        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(200000, 0)
            .addExecutorLzComposeOption(0, 500000, 0);
        bytes memory composeMsg = hex"1234";
        SendParam memory sendParam = SendParam(
            cEid,
            addressToBytes32(address(composer)),
            tokensToSend,
            tokensToSend,
            options,
            composeMsg,
            ""
        );
        MessagingFee memory fee = aOFTAdapter.quoteSend(sendParam, false);

        assertEq(aERC20.balanceOf(userA), initialBalance);
        assertEq(cERC20.balanceOf(address(composer)), 0);

        vm.prank(userA);
        (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) = aOFTAdapter.send{ value: fee.nativeFee }(
            sendParam,
            fee,
            payable(address(this))
        );
        verifyPackets(cEid, addressToBytes32(address(cOFTAdapter)));

        // lzCompose params
        uint32 dstEid_ = cEid;
        address from_ = address(cOFTAdapter);
        bytes memory options_ = options;
        bytes32 guid_ = msgReceipt.guid;
        address to_ = address(composer);
        bytes memory composerMsg_ = OFTComposeMsgCodec.encode(
            msgReceipt.nonce,
            aEid,
            oftReceipt.amountReceivedLD,
            abi.encodePacked(addressToBytes32(userA), composeMsg)
        );
        this.lzCompose(dstEid_, from_, options_, guid_, to_, composerMsg_);

        assertEq(aERC20.balanceOf(userA), initialBalance - tokensToSend);
        assertEq(cERC20.balanceOf(address(composer)), tokensToSend);

        assertEq(composer.from(), from_);
        assertEq(composer.guid(), guid_);
        assertEq(composer.message(), composerMsg_);
        assertEq(composer.executor(), address(this));
        assertEq(composer.extraData(), composerMsg_); // default to setting the extraData to the message as well to test
    }
}
