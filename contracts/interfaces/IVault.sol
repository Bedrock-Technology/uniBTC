// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IVault {
    function execute(
        address target,
        bytes memory data,
        uint256 value
    ) external returns (bytes memory);
}
