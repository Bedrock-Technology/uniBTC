// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperUtils} from "./utils/HelperUtils.s.sol"; // Utility functions for JSON parsing and chain info
import {HelperConfig} from "./HelperConfig.s.sol"; // Network configuration helper
import {IERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract TransferTokens is Script {
    function run() external {}

    function sendToken(uint256 _destinationChainId, uint256 _amount) external {
        // Get the chain name based on the current chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);

        // Fetch the network configuration for the current chain
        HelperConfig helperConfig = new HelperConfig();
        (, address router,,,, address tokenAddress) = helperConfig.activeNetworkConfig();
        // Retrieve the remote network configuration
        HelperConfig.NetworkConfig memory remoteNetworkConfig =
            HelperUtils.getNetworkConfig(helperConfig, _destinationChainId);
        uint64 destinationChainSelector = remoteNetworkConfig.chainSelector;

        require(tokenAddress != address(0), "Invalid token address");
        require(_amount > 0, "Invalid amount to transfer");
        require(destinationChainSelector != 0, "Chain selector not defined for the destination chain");

        // Determine the fee token to use based on feeType
        address feeTokenAddress = address(0); // Use native token (e.g., ETH, AVAX);
        vm.startBroadcast(vm.envAddress("OWNER_ADDRESS"));

        // Connect to the CCIP router contract
        IRouterClient routerContract = IRouterClient(router);

        // Check if the destination chain is supported by the router
        require(routerContract.isChainSupported(destinationChainSelector), "Destination chain not supported");

        // Prepare the CCIP message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(msg.sender), // Receiver address on the destination chain
            data: abi.encode(), // No additional data
            tokenAmounts: new Client.EVMTokenAmount[](1), // Array of tokens to transfer
            feeToken: feeTokenAddress, // Fee token (native or LINK)
            extraArgs: abi.encodePacked(
                bytes4(keccak256("CCIP EVMExtraArgsV1")), // Extra arguments for CCIP (versioned)
                abi.encode(uint256(0)) // Placeholder for future use
            )
        });

        // Set the token and amount to transfer
        message.tokenAmounts[0] = Client.EVMTokenAmount({token: tokenAddress, amount: _amount});

        // Approve the router to transfer tokens on behalf of the sender
        IERC20(tokenAddress).approve(router, _amount);

        // Estimate the fees required for the transfer
        uint256 fees = routerContract.getFee(destinationChainSelector, message);
        console.log("Estimated fees:", fees);

        // Send the CCIP message and handle fee payment
        bytes32 messageId = routerContract.ccipSend{value: fees}(destinationChainSelector, message);

        // Log the Message ID
        console.log("chainName:", chainName);
        console.log("Message ID:");
        console.logBytes32(messageId);

        // Provide a URL to check the status of the message
        string memory messageUrl = string(
            abi.encodePacked(
                "Check status of the message at https://ccip.chain.link/msg/", HelperUtils.bytes32ToHexString(messageId)
            )
        );
        console.log(messageUrl);

        vm.stopBroadcast();
    }
}
