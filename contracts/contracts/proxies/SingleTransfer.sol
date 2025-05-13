// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract SingleTransfer {
    receive() external payable {
        assembly {
            return(0,59200)
        }
    }

    function consumeGas() public pure {
        uint256 i = 0;
        while (true) {
            i++;
        }
    }
}
