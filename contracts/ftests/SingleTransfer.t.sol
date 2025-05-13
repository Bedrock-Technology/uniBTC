// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contracts/proxies/SingleTransfer.sol";
import "../contracts/proxies/Challenge.sol";

contract SingleTransferTest is Test {
    SingleTransfer public singleTransfer;
    BatchTransfer public bTransfer;
    address public tokenHolder;

    function setUp() public {
        tokenHolder = makeAddr("holder");
        deal(tokenHolder, 2 ether);
        vm.startPrank(tokenHolder);
        singleTransfer = new SingleTransfer();
        bTransfer = new BatchTransfer();
        vm.stopPrank();
    }

    function test_singleTransfer() public {
        vm.startPrank(tokenHolder);
        uint256 amount = 1 ether;
        address payable[] memory recipients = new address payable[](1);
        recipients[0] = payable(address(singleTransfer));
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        bTransfer.batchTransfer{value: 1 ether,gas: 10000}(recipients, amounts);
        vm.stopPrank();
    }
}