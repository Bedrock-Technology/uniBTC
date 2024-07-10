// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AirDropper {
    using SafeERC20 for IERC20;

    /**
     * @dev Distribute separately '_amount' of '_token' to each of '_recipients'.
     * The minimum allowance of '_token' to this contract is '_amount * _recipients.length'.
     */
    function airdrop(address _token, address[] calldata _recipients, uint256 _amount) external {
        IERC20 token = IERC20(_token);

        token.safeTransferFrom(msg.sender, address(this), _amount * _recipients.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            token.safeTransfer(_recipients[i], _amount);
        }
    }
}