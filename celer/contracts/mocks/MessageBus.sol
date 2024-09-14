// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

contract MessageBus {
    uint256 public constant feeBase = 15000000000000;
    uint256 public constant feePerByte = 150000000000;

    struct ExecMsgArgs {
        uint64 _srcChainId;
        address _senderPeer;
        address _receiverPeer;
        address _tokenSender;
        address _tokenRecipient;
        uint256 _amount;
        uint256 _nonce;
    }

    struct Request {
        address sender;
        address recipient;
        uint256 amount;
        uint64 nonce;
    }

    event Message(address indexed sender, address receiver, uint256 dstChainId, bytes message, uint256 fee);


    /**
     * ======================================================================================
     *
     * Functions on MessageBusSender
     *
     * ======================================================================================
     */

    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable {
        _sendMessage(_dstChainId, _message);
        emit Message(msg.sender, _receiver, _dstChainId, _message, msg.value);
    }

    function _sendMessage(uint256 _dstChainId, bytes calldata _message) private {
        require(_dstChainId != block.chainid, "Invalid chainId");
        uint256 minFee = calcFee(_message);
        require(msg.value >= minFee, "Insufficient fee");
    }

    function calcFee(bytes calldata _message) public view returns (uint256) {
        return feeBase + _message.length * feePerByte;
    }


    /**
     * ======================================================================================
     *
     * Functions on MessageBusReceiver
     *
     * ======================================================================================
     */

    function executeMessage(
        uint64 _srcChainId,
        address _senderPeer,
        address _receiverPeer,
        address _tokenSender,
        address _tokenRecipient,
        uint256 _amount,
        uint64 _nonce
    ) external payable {
        bytes memory message = abi.encode(
            Request({sender: _tokenSender, recipient: _tokenRecipient, amount: _amount, nonce: _nonce})
        );
        (bool ok, bytes memory res) = _receiverPeer.call{value: msg.value}(
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("executeMessage(address,uint64,bytes,address)"))),
                _senderPeer,
                _srcChainId,
                message,
                msg.sender
            )
        );
        if (!ok) {
            revert();
        }
    }
}
