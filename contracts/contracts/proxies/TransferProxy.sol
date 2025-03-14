// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IVault.sol";

contract TransferProxy is Ownable {
    address public immutable vault;
    address public immutable to;
    using Address for address;

    /**
     * @dev initiate vault and to, the to must be a contract.
     */
    constructor(address _vault, address _to) Ownable() {
        require(_to.isContract(), "not a contract address");
        vault = _vault;
        to = _to;
    }

    /**
     * @dev transfer given amount of native token from vault to the given '_to' contract.
     */
    function transfer(uint256 _amount) external onlyOwner {
        require(_amount > 0, "amount error");
        IVault(vault).execute(to, "", _amount);
    }

    /**
     * @dev transfer given amount of ERC20 token from vault to the given '_to' contract.
     */
    function transfer(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(0) && _amount > 0, "bad params");
        bytes memory data = abi.encodeWithSelector(IERC20.transfer.selector, to, _amount);
        IVault(vault).execute(_token, data, 0);
    }
}
