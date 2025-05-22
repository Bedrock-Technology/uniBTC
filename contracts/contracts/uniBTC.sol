// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract uniBTC is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");

    address public freezeToRecipient;
    mapping(address => bool) public frozenUsers;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin, address minter, address[] memory _frozenUsers) reinitializer(2) public {
        __ERC20_init("uniBTC", "uniBTC");
        __ERC20Burnable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);


        freezeToRecipient = address(0x899c284A89E113056a72dC9ade5b60E80DD3c94f);

        for(uint256 i = 0; i < _frozenUsers.length; ++i) {
            frozenUsers[_frozenUsers[i]] = true;
        }
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(uint256 amount) override public onlyRole(MINTER_ROLE) {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) override public onlyRole(MINTER_ROLE) {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev Batch transfer amount to recipient
     * @notice that excessive gas consumption causes transaction revert
     */
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length > 0, "USR001");
        require(recipients.length == amounts.length, "USR002");

        for(uint256 i = 0; i < recipients.length; ++i) {
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (frozenUsers[sender]) {
            require(recipient == freezeToRecipient, "USR016");
        }
        super._transfer(sender, recipient, amount);
    }

    function freezeUsers(address[] memory users) public onlyRole(FREEZER_ROLE) {
        for(uint256 i = 0; i < users.length; ++i) {
            frozenUsers[users[i]] = true;
        }
    }

    function unfreezeUsers(address[] memory users) public onlyRole(FREEZER_ROLE) {
        for(uint256 i = 0; i < users.length; ++i) {
            frozenUsers[users[i]] = false;
        }
    }

    /**
     * ======================================================================================
     *
     * ADMIN FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * @dev set freezeToRecipient
     */
    function setFreezeToRecipient(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        freezeToRecipient = recipient;
    }

    /**
     * @dev withdraw token from contract
     */
    function withdraw(address _token, address _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_token == address(0)) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).transfer(_to, _amount);
        }
    }
}
