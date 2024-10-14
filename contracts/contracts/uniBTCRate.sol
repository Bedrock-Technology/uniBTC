// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../interfaces/IUniBTCRate.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract uniBTCRate is Initializable, AccessControlUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint256 public constant MULTIPLIER = 1e18;

    uint256 public totalReserve;
    uint256 public totalTokenSupply;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _defaultAdmin) initializer public {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(OPERATOR_ROLE, _defaultAdmin);
    }

    /**
     * @dev Function to calc the rate
     */
    function getRate() external view returns (uint256) {
        return MULTIPLIER * totalReserve / totalTokenSupply;
    }

    /**
     * @dev Update reserve and supply
     */
    function update(uint256 _totalReserve, uint256 _totalTokenSupply) external onlyRole(OPERATOR_ROLE) {
        totalReserve = _totalReserve;
        totalTokenSupply = _totalTokenSupply;
    
        emit Updated(_totalReserve, _totalTokenSupply);
    }

    // event
    event Updated(uint256 totalReserve, uint256 totalTokenSupply);
}
