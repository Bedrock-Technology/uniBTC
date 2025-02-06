// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {Sigma} from "../contracts/Sigma.sol";

contract Set is Script {
    address public deployer;
    address public owner;

    function setUp() public {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        owner = vm.envAddress("OWNER_ADDRESS");
    }

    //forge script fscripts/set_Sigma.s.sol --sig 'setTokenHolders(address,address,address,address[])' '0x' 0x' '0x' "[0x,0x]" --rpc-url $RPC_ETH_SEPOLIA --account $OWNER --broadcast
    function setTokenHolders(address sigma, address leadingToken, address token, address[] memory holder) external {
        Sigma sigmaIns = Sigma(payable(sigma));
        vm.startBroadcast(owner);
        Sigma.Pool memory pool = Sigma.Pool(token, holder);
        Sigma.Pool[] memory pools = new Sigma.Pool[](1);
        pools[0] = pool;
        sigmaIns.setTokenHolders(leadingToken, pools);
        vm.stopBroadcast();
        console.log("leadingToken", leadingToken);
        console.log("token", token);
        console.log("holders");
        for (uint256 index = 0; index < holder.length; index++) {
            console.log("holder", holder[index]);
        }
    }
}
