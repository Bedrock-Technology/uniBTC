// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/iface.sol";

contract GenericFacade is Initializable, OwnableUpgradeable {
    address public vault;

    receive() external payable {
        revert("value only accepted by the Vault contract");
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _vault) initializer public {
        __Ownable_init();

        vault = _vault;
    }

    /**
     * @dev withdraw native BTC, available only in the Bitcoin ecosystem
     */
    function adminWithdraw(uint256 _amount, address _target) external onlyOwner {
        IVault(vault).adminWithdraw(_amount, _target);
    }

    /**
     * @dev withdraw wrapped BTC
     */
    function adminWithdraw(address _token, uint256 _amount, address _target) external onlyOwner {
        IVault(vault).adminWithdraw(_token, _amount, _target);
    }
}
