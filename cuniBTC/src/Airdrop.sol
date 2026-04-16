// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Airdrop is Initializable, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct Dist {
        /// @notice The root of Merkle tree for airdrop distribution.
        bytes32 root;
        /// @notice The timestamp when this distribution becomes active.
        uint256 activatedAt;
        /// @notice The duration in seconds that this distribution remains active. zero means no expiration.
        uint256 duration;
        /// @notice The flag indicating if this distribution is disabled.
        bool disabled;
        /// @notice The address of the token used for airdrop for this epoch, if zero address, native token is used.
        address token;
    }

    /// @notice Mapping of epoch to its distribution root data.
    mapping(uint256 => Dist) private merkleRoots;
    /// @notice Mapping of epoch and user address to claim status.
    mapping(uint256 => mapping(address => bool)) private claimed;
    /// @notice Delay in timestamp (seconds) before a posted root can be claimed against.
    uint256 public activationDelay;
    /// @notice Length of each airdrop epoch added.
    uint256 public epochAdded;

    receive() external payable {}

    /**
     * ======================================================================================
     *
     * CONSTRUCTOR
     *
     * ======================================================================================
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * ======================================================================================
     *
     * ADMIN
     *
     * ======================================================================================
     */
    /**
     * @notice Initializes the airdrop contract with required parameters.
     * @dev Sets up roles and initializes core contract parameters.
     * @param _activationDelay The initial delay before claims can be made.
     * @param _admin The address of the contract administrator.
     */
    function initialize(uint256 _activationDelay, address _admin) public initializer {
        require(_admin != address(0), "SYS001");

        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);

        _setDelay(_activationDelay);
        epochAdded = 0;
    }

    /**
     * @notice Pauses all contract operations.
     * @dev Only callable by accounts with PAUSER_ROLE.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses all contract operations.
     * @dev Only callable by accounts with PAUSER_ROLE.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Sets the delay in timestamp before a posted root can be claimed against.
     * @dev Only callable by accounts with OPERATOR_ROLE.
     * @param _activationDelay The new value for activationDelay.
     */
    function setDelay(uint256 _activationDelay) external onlyRole(OPERATOR_ROLE) {
        require(_activationDelay < type(uint32).max, "USR001");
        _setDelay(_activationDelay);
    }

    /**
     * @notice Submits a new Merkle root and starts a new airdrop epoch.
     * @dev Only callable by accounts with OPERATOR_ROLE.
     * @param _newRoot The Merkle root of the new distribution.
     * @param _duration The duration in seconds for which this distribution is valid.
     * @param _token The address of the token used for airdrop for this epoch, if zero address, native token is used.
     */
    function submitRoot(bytes32 _newRoot, uint256 _duration, address _token, uint256 _epoch)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(_newRoot != bytes32(0), "SYS002");
        require(merkleRoots[_epoch].root == bytes32(0), "USR002");
        epochAdded++;

        merkleRoots[_epoch] = Dist({
            root: _newRoot,
            activatedAt: uint256(block.timestamp) + activationDelay,
            duration: _duration,
            disabled: false,
            token: _token
        });

        emit MerkleRootSubmit(_epoch, _newRoot, _duration, uint256(block.timestamp) + activationDelay, _token);
    }

    /**
     * @dev Only callable by accounts with OPERATOR_ROLE.
     * @param _newRoot The new Merkle root to replace the current one.
     * @param _epoch The epoch for which to update the root.
     */
    function updateRoot(bytes32 _newRoot, uint256 _epoch) external onlyRole(OPERATOR_ROLE) {
        require(merkleRoots[_epoch].root != bytes32(0), "USR002");
        require(_newRoot != bytes32(0), "USR003");
        emit MerkleRootUpdate(_epoch, merkleRoots[_epoch].root, _newRoot);
        merkleRoots[_epoch].root = _newRoot;
    }

    /**
     * @notice Updates the token for the current epoch.
     * @dev Only callable by accounts with OPERATOR_ROLE.
     * @param _token The new token address.
     * @param _epoch The epoch for which to update the token.
     */
    function updateToken(address _token, uint256 _epoch) external onlyRole(OPERATOR_ROLE) {
        require(merkleRoots[_epoch].root != bytes32(0), "USR002");
        emit TokenUpdate(_epoch, merkleRoots[_epoch].token, _token);
        merkleRoots[_epoch].token = _token;
    }

    /**
     * @notice Updates the valid duration for the current epoch.
     * @dev Only callable by accounts with OPERATOR_ROLE.
     * @param _duration The new duration in seconds.
     */
    function updateDuration(uint256 _duration, uint256 _epoch) external onlyRole(OPERATOR_ROLE) {
        require(merkleRoots[_epoch].root != bytes32(0), "USR002");
        emit ValidDurationUpdate(_epoch, merkleRoots[_epoch].duration, _duration);
        merkleRoots[_epoch].duration = _duration;
    }

    /**
     * @notice Sets the distribution status for the current epoch.
     * @dev Only callable by accounts with OPERATOR_ROLE.
     * @param _disabled The status to set (true = disabled, false = enabled).
     */
    function setAirdrop(bool _disabled, uint256 _epoch) external onlyRole(OPERATOR_ROLE) {
        require(merkleRoots[_epoch].root != bytes32(0), "USR002");
        Dist storage distribution = merkleRoots[_epoch];
        emit DistributionDisabledSet(_epoch, distribution.disabled, _disabled);
        distribution.disabled = _disabled;
    }

    /**
     * @notice Withdraws tokens from the contract.
     * @dev Only callable by accounts with DEFAULT_ADMIN_ROLE.
     * @param _token The address of the token to withdraw (use address(0) for native tokens).
     * @param _to The address to send the withdrawn tokens to.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdraw(address _token, address _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_to != address(0), "USR003");
        if (_token == address(0)) {
            payable(_to).transfer(_amount);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), _to, _amount);
        }
    }

    /**
     * ======================================================================================
     *
     * INTERNAL FUNCTIONS
     *
     * ======================================================================================
     */
    /**
     * @notice Updates the activation delay for airdrop claims.
     * @dev Internal function to update the delay before claims can be made.
     * @param _activationDelay The new activation delay value in seconds.
     */
    function _setDelay(uint256 _activationDelay) internal {
        emit ActivationDelaySet(activationDelay, _activationDelay);
        activationDelay = _activationDelay;
    }

    /**
     * @notice Checks if the current epoch's airdrop is active and valid.
     * @dev Returns false if: no active epoch, distribution disabled, or expired.
     * @return True if the current epoch's airdrop is valid and active.
     */
    function _isActive(uint256 _epoch) internal view returns (bool) {
        if (merkleRoots[_epoch].root == bytes32(0)) return false;

        Dist memory distribution = merkleRoots[_epoch];
        if (distribution.disabled) return false;

        uint256 currentTime = block.timestamp;
        if (currentTime < distribution.activatedAt) {
            return false;
        }
        if (distribution.duration > 0) {
            if (currentTime > distribution.activatedAt + distribution.duration) {
                return false;
            }
        }
        return true;
    }

    function _claim(uint256 _amount, bytes32[] calldata _proof, uint256 _epoch) internal {
        require(_isActive(_epoch), "USR006");
        require(!claimed[_epoch][msg.sender], "USR005");

        Dist memory distribution = merkleRoots[_epoch];

        // Verify Merkle proof.
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, _amount))));
        require(MerkleProofUpgradeable.verify(_proof, distribution.root, leaf), "USR009");

        // Mark as claimed.
        claimed[_epoch][msg.sender] = true;

        if (distribution.token == address(0)) {
            (bool ok,) = payable(msg.sender).call{value: _amount}("");
            require(ok, "SYS002");
        } else {
            SafeERC20.safeTransfer(IERC20(distribution.token), msg.sender, _amount);
        }

        emit AirdropClaimed(_epoch, msg.sender, distribution.token, _amount);
    }

    /**
     * ======================================================================================
     *
     * EXTERNAL FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * @notice Claims airdrop tokens for the current epoch and locks them in VotingEscrow.
     * @dev Verifies Merkle proof and handles token transfer and locking.
     * @param _amount The amount of tokens to claim.
     * @param _proof The Merkle proof verifying the claim eligibility.
     * @param _epoch The epoch number for which to claim the airdrop.
     */
    function claim(uint256 _amount, bytes32[] calldata _proof, uint256 _epoch) external whenNotPaused nonReentrant {
        _claim(_amount, _proof, _epoch);
    }

    /**
     * @notice Claims airdrop tokens for multiple epochs and locks them in VotingEscrow.
     * @dev Verifies Merkle proofs and handles token transfers and locking.
     * @param _amount The amounts of tokens to claim.
     * @param _proof The Merkle proofs verifying the claim eligibility.
     * @param _epoch The epoch numbers for each claim.
     */
    function claim(uint256[] calldata _amount, bytes32[][] calldata _proof, uint256[] calldata _epoch)
        external
        whenNotPaused
        nonReentrant
    {
        require(_amount.length == _proof.length && _amount.length == _epoch.length, "USR010");
        for (uint256 i = 0; i < _amount.length; i++) {
            _claim(_amount[i], _proof[i], _epoch[i]);
        }
    }

    /**
     * @notice Retrieves the distribution root information for a specific epoch.
     * @dev Returns the complete Dist struct.
     * @param _epoch The epoch number to query.
     * @return The Dist struct containing root, activatedAt, duration and disabled status.
     */
    function getRoot(uint256 _epoch) external view returns (Dist memory) {
        return merkleRoots[_epoch];
    }

    /**
     * @notice Checks if a list of users have claimed their airdrop for a specific epoch.
     * @dev Returns the claim status for each user in the provided address array.
     * @param _epoch The epoch number to query.
     * @param _users An array of user addresses to check.
     * @return An array of boolean values indicating claim status for each user.
     */
    function hasClaimed(uint256 _epoch, address[] calldata _users) external view returns (bool[] memory) {
        require(_users.length > 0, "SYS002");
        bool[] memory claims = new bool[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            claims[i] = claimed[_epoch][_users[i]];
        }
        return claims;
    }

    /**
     * @notice Checks if a specific user has claimed their airdrop for multiple epochs.
     * @dev Returns the claim status for each epoch in the provided array.
     * @param _user The user address to check.
     * @param _epoch An array of epoch numbers to query.
     * @return An array of boolean values indicating claim status for each epoch.
     */
    function hasClaimed(address _user, uint256[] calldata _epoch) external view returns (bool[] memory) {
        require(_epoch.length > 0, "SYS002");
        bool[] memory claims = new bool[](_epoch.length);
        for (uint256 i = 0; i < _epoch.length; i++) {
            require(merkleRoots[_epoch[i]].root != bytes32(0), "USR002");
            claims[i] = claimed[_epoch[i]][_user];
        }
        return claims;
    }

    /**
     * @notice Checks if the current epoch's airdrop is active and valid.
     * @dev Returns false if: no active epoch, distribution disabled, not activated yet, or expired.
     * @return True if the current epoch's airdrop is valid and active.
     */
    function isActive(uint256 _epoch) external view returns (bool) {
        return _isActive(_epoch);
    }

    /**
     * ======================================================================================
     *
     * EVENTS
     *
     * ======================================================================================
     */
    /// @notice Emitted when a new Merkle root is submitted for a new epoch.
    event MerkleRootSubmit(
        uint256 indexed epoch, bytes32 root, uint256 rewardsValidTime, uint256 activatedAt, address token
    );
    /// @notice Emitted when the Merkle root is updated for the current epoch.
    event MerkleRootUpdate(uint256 indexed epoch, bytes32 preRoot, bytes32 root);
    event TokenUpdate(uint256 indexed epoch, address preToken, address token);
    /// @notice Emitted when the valid duration is updated for the current epoch.
    event ValidDurationUpdate(uint256 indexed epoch, uint256 preValidDuration, uint256 validDuration);
    /// @notice Emitted when an airdrop is claimed by a user.
    event AirdropClaimed(uint256 indexed epoch, address indexed user, address tokenAddress, uint256 amount);
    /// @notice Emitted when the activation delay is updated.
    event ActivationDelaySet(uint256 oldActivationDelay, uint256 newActivationDelay);
    /// @notice Emitted when the distribution status is changed.
    event DistributionDisabledSet(uint256 indexed epoch, bool preStatus, bool status);
}
