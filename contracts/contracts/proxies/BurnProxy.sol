// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IMintableContract} from "../../interfaces/IMintableContract.sol";

contract BurnProxy is Ownable {
    address public immutable vault;
    address public immutable token;

    using Address for address;

    /**
     * @dev initiate vault and token, the token must be a contract.
     */
    constructor(address _vault, address _token) Ownable() {
        require(_token.isContract(), "not a contract address");
        vault = _vault;
        token = _token;
    }

    /**
     * @dev burn given amount of token from vault.
     */
    function burn(uint256 _amount) external onlyOwner {
        require(_amount > 0, "bad params");
        bytes memory data = abi.encodeWithSelector(IMintableContract.burn.selector, _amount);
        IVault(vault).execute(token, data, 0);
    }
}
