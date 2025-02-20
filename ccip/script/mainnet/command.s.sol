// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {CCIPPeer} from "../../src/ccipPeer.sol";
import {uniBTC} from "../../src/mocks/uniBTC.sol";

contract Command is Script {
    // forge script script/mainnet/command.s.sol:Command --sig 'sendToken(address,uint64,address,uint256,uint256,bytes)' \
    // 0x55A67cf07B8a9A09fB6d565279287Cfe4aB60edC \
    // 1673871237479749969 \
    // 0xac07f2721EcD955c4370e7388922fA547E922A4f \
    // 1000 \
    // 34 \
    // 0xc826184a4b48d67958015ea819a5eb41c5c238a59b0b1f1bfad0edb98a8fc11c4043b8c5b06337345413761ccfe7630a9bec818a40ce3eb2d6966d43552752101c \
    // --rpc-url $RPC_ETH --sender $OWNER_ADDRESS --account $OWNER --broadcast
    function sendToken(
        address _ccipPeerAddr,
        uint64 _destinationChainSelector,
        address _recipient,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) public {
        CCIPPeer ccipPeerIns = CCIPPeer(payable(_ccipPeerAddr));
        uniBTC uniBTCIns = uniBTC(ccipPeerIns.uniBTC());

        vm.startBroadcast();
        uint256 allowance = uniBTCIns.allowance(msg.sender, _ccipPeerAddr);
        console.log("allowance:", allowance);
        if (allowance < _amount) {
            uniBTCIns.approve(_ccipPeerAddr, 10 * _amount);
        }
        uint256 fees = ccipPeerIns.estimateSendTokenFees(_destinationChainSelector, _recipient, _amount);
        console.log("est fees:%d", fees);
        // send to owner, 1uniBTC
        ccipPeerIns.sendToken{value: fees}(_destinationChainSelector, _recipient, _amount, _nonce, _signature);
        vm.stopBroadcast();
    }
}
