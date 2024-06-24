// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@celer-network/contracts/message/framework/MessageApp.sol";
import "@celer-network/contracts/message/interfaces/IMessageBus.sol";
import "../interfaces/iface.sol";

contract Peer is MessageApp, Pausable, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;
    using Address for address payable;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint private constant MIN_AMT_UNIT = 1e5;
    uint private constant MSG_LEN = 128;

    struct Request {
        address sender;
        address recipient;
        uint256 amount;
        uint64 nonce;
    }

    /**
     * @dev The minimum amount to make a cross-chain transfer.
     */
    uint256 public minTransferAmt = 20 * MIN_AMT_UNIT;

    /**
    * @dev The local uniBTC ERC-20 token address.
     */
    address public immutable uniBTC;

    /**
     * @dev The map for configuring peers to chain ID.
     */
    mapping(uint64 => address) public peers;

    /**
     * @dev The counter to record each cross-chain transaction
     */
    uint64 public nonce;

    receive() external payable { }

    constructor(address _messageBus, address _uniBTC) MessageApp(_messageBus) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);

        uniBTC = _uniBTC;
    }


    /**
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * SENDER FUNCTIONS
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */


    /**
     * @dev Burn uniBTC on the source chain and mint the corresponding amount of uniBTC on the destination chain
     * for the given recipient.
     */
    function sendToken(
        uint64 _dstChainId,
        address _recipient,
        uint256 _amount
    ) external payable whenNotPaused {
        address dstPeer = peers[_dstChainId];

        require(_dstChainId != block.chainid, "invalid chainId");
        require(dstPeer != address(0), "destination peer does not exist");
        require(_amount >= minTransferAmt, "invalid amount to transfer");
        require(_recipient != address(0), "transfer to the zero address");
        require(msg.value == calcFee(), "incorrect fee");

        // Request to mint uniBTC
        bytes memory message = abi.encode(
            Request({sender: msg.sender, recipient: _recipient, amount: _amount, nonce: nonce})
        );
        sendMessage(
            dstPeer,
            _dstChainId,
            message,
            msg.value
        );

        // Burn uniBTC
        IMintableContract(uniBTC).burnFrom(msg.sender, _amount);
        emit SrcBurned(_dstChainId, dstPeer, msg.sender, _recipient, _amount, nonce);
    }

    /**
     * @dev The helper function that calculates the dynamic message fee for sending one cross-chain transfer request.
     */
    function calcFee() public view returns (uint256) {
        ISGNFeeQuerier fq = ISGNFeeQuerier(messageBus);
        return fq.feeBase() + MSG_LEN * fq.feePerByte();
    }

    /**
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * RECEIVER FUNCTIONS
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * @dev Called by MessageBus to execute a message to mint uniBTC on the destination chain.
     */
    function executeMessage(
        address _srcPeer,
        uint64 _srcChainId,
        bytes calldata _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        require(_srcPeer != peers[_srcChainId], "illegal remote caller");

        Request memory req = abi.decode((_message), (Request));

        // Mint uniBTC
        IMintableContract(uniBTC).mint(req.recipient, req.amount);
        emit DstMinted(_srcChainId, _srcPeer, req.sender, req.recipient, req.amount, req.nonce);

        return ExecutionStatus.Success;
    }


    /**
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * ADMIN Functions
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * @dev Claim native tokens that are accidentally sent to this contract.
     */
    function claimTokens(address _recipient, uint256 _amount) onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant external {
        payable(_recipient).sendValue(_amount);
        emit NativeTokensClaimed(_recipient, _amount);
    }

    /**
     * @dev Claim ERC-20 tokens that are accidentally sent to this contract.
     */
    function claimTokens(address _recipient, address _token, uint256 _amount) onlyRole(DEFAULT_ADMIN_ROLE) external {
        IERC20(_token).safeTransfer(_recipient, _amount);
        emit ERC20TokensClaimed(_recipient, _token, _amount);
    }

    /**
     * @dev Set the minimum amount to make a cross-chain transfer.
     */
    function setMinTransferAmt(uint256 _minimalAmt) external onlyRole(MANAGER_ROLE) {
        require(_minimalAmt > 0 && _minimalAmt % MIN_AMT_UNIT == 0, "minimum value should be a positive multiple of 10000");
        minTransferAmt = _minimalAmt;
        emit MinTransferAmtSet(_minimalAmt);
    }

    /**
     * @dev Configure peers to chain ID so that they can communicate with each other and avoid illegal minting requests.
     */
    function configurePeers(uint64[] calldata _chainIds, address[] calldata _peers) external onlyRole(MANAGER_ROLE) {
        require(_chainIds.length > 0 && _chainIds.length == _peers.length, "invalid input array lengths");

        for (uint256 i = 0; i < _chainIds.length; i++) {
            uint64 chainId = _chainIds[i];
            address peer = _peers[i];

            require(chainId != 0, "chain ID cannot be zero");
            require(peer != address(0), "invalid peer address");

            peers[chainId] = peer;
        }

        emit PeersConfigured(_chainIds, _peers);
    }

    /**
     * @dev Pause the contract
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * CONTRACT EVENTS
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */
    event SrcBurned(uint64 dstChainId, address dstPeer, address sender, address recipient, uint256 amount, uint256 nonce);
    event DstMinted(uint64 srcChainId, address srcPeer, address sender, address recipient, uint256 amount, uint256 nonce);

    event NativeTokensClaimed(address recipient, uint256 amount);
    event ERC20TokensClaimed(address recipient, address token, uint256 amount);

    event MinTransferAmtSet(uint256 amount);
    event PeersConfigured(uint64[] chainIds, address[] peers);
}

