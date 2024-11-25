// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { MintBurnOFTAdapter, IMintableBurnable } from "../../contracts/MintBurnOFTAdapter.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// @dev WARNING: This is for testing purposes only
contract MintBurnOFTAdapterMock is MintBurnOFTAdapter {
    constructor(
        address _token,
        IMintableBurnable _minterBurner,
        address _lzEndpoint,
        address _delegate
    ) MintBurnOFTAdapter(_token, _minterBurner, _lzEndpoint, _delegate) Ownable(_delegate) {}
}