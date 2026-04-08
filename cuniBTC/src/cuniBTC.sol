// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract cuniBTC is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public redeemRouter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _defaultAdmin, address _minter, string memory _name, string memory _symbol)
        public
        initializer
    {
        __ERC20_init(_name, _symbol);
        __ERC20Burnable_init();
        __AccessControl_init();
        require(_defaultAdmin != address(0) && _minter != address(0), "SYS001");
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0, "SYS002");

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(MINTER_ROLE, _minter);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(uint256 amount) public override {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(redeemRouter != address(0), "SYS001");
        if (recipient != redeemRouter) {
            revert("TRANSFER_NOT_ALLOWED");
        }
        super._transfer(sender, recipient, amount);
    }

    /**
     * ======================================================================================
     *
     * ADMIN FUNCTIONS
     *
     * ======================================================================================
     */

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

    /**
     * @dev set redeem router address
     */
    function setRedeemRouter(address _redeemRouter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        redeemRouter = _redeemRouter;
    }
}
