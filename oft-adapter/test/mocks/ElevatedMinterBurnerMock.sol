pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { OFTCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";

/// @title Interface for mintable and burnable tokens
interface IMintableBurnable {
    
    /**
     * @notice Burns tokens from a specified account
     * @param _from Address from which tokens will be burned
     * @param _amount Amount of tokens to be burned
     * @return success Indicates whether the operation was successful
     */
    function burn(address _from, uint256 _amount) external returns (bool success);

    /**
     * @notice Mints tokens to a specified account
     * @param _to Address to which tokens will be minted
     * @param _amount Amount of tokens to be minted
     * @return success Indicates whether the operation was successful
     */
    function mint(address _to, uint256 _amount) external returns (bool success);
}

/// @title Operatable
/// @notice Enables granular access control by designating operators
contract Operatable is Ownable {
    /// @notice Triggered when an operator is added or removed
    event OperatorChanged(address indexed operator, bool status);

    /// @notice Error to indicate unauthorized access by non-operators
    error NotAllowedOperator();

    /// @dev Mapping of addresses to their operator status
    mapping(address => bool) public operators;

    /// @notice Initializes the contract by setting the deployer as an operator
    /// @param _owner Address that will own the contract
    constructor(address _owner) Ownable(_owner) {
        operators[msg.sender] = true;
    }

    /// @notice Ensures function is called by an operator
    modifier onlyOperators() {
        if (!operators[msg.sender]) {
            revert NotAllowedOperator();
        }
        _;
    }

    /**
     * @notice Allows the owner to set or unset operator status of an address
     * @param operator The address to be modified
     * @param status Boolean indicating whether the address should be an operator
     */
    function setOperator(address operator, bool status) external onlyOwner {
        operators[operator] = status;
        emit OperatorChanged(operator, status);
    }
}

/// @title ElevatedMinterBurner
/// @notice Manages minting and burning of tokens through delegated control to operators
contract ElevatedMinterBurner is IMintableBurnable, Operatable {
    /// @notice Reference to the token with mint and burn capabilities
    IMintableBurnable public immutable token;

    /**
     * @notice Initializes the contract by linking a token and setting the owner
     * @param token_ The mintable and burnable token interface address
     * @param _owner The owner of this contract, who can set operators
     */
    constructor(IMintableBurnable token_, address _owner) Operatable(_owner) {
        token = token_;
    }

    function burn(address from, uint256 amount) external override onlyOperators returns (bool) {
        return token.burn(from, amount);
    }

    function mint(address to, uint256 amount) external override onlyOperators returns (bool) {
        return token.mint(to, amount);
    }
}