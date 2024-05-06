// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PaymentChannel {
    address payable public sender;
    address payable public recipient;
    uint256 public senderBalance; // Sender balance of the channel
    uint256 public recipientBalance; // Recipient balance of the channel
    uint256 sequenceNum; // State sequence number of the channel
    uint256 public expiration; // Channel state, is not closing if expiration is 0

    constructor(address payable _recipient) payable {
        sender = payable(msg.sender);
        recipient = _recipient;
        senderBalance = msg.value;
    }

    // Deposit function
    receive() external payable {
        require(expiration == 0 || block.timestamp < expiration, "Channel closed");
        if (msg.sender == sender) {
            senderBalance += msg.value;
        } else {
            recipientBalance += msg.value;
        }
    }

    // Update channel state
    function update(bytes memory _senderSignature, bytes memory _recipientSignature, uint256 _sequenceNum, uint256 _senderBalance, uint256 _recipientBalance, bytes32[] memory _hashList, bytes32[] memory _preimageList) public {
        // Check channel state
        require(expiration == 0 || block.timestamp < expiration, "Channel closed");
        // Check number of hash and preimages
        require(_hashList.length == _preimageList.length, "Inconsistency between hash number and preimage number");
        // Check ETH transfered.
        require(_senderBalance + _recipientBalance == senderBalance + recipientBalance, "The total amount of ETH doesn't match");
        require(_sequenceNum > sequenceNum, "New Sequence Number is lower than the current Sequence Number");
        // Use the keccak256 function to calculate the hash value of the message.
        // Make sure the hash value of them are identical.
        bytes32 messageHash = keccak256(abi.encodePacked(_sequenceNum, _senderBalance, _recipientBalance, _hashList));

        // Recover the public address from message and signature.
        // Make sure the public address is the sender.
        address senderAccount = _recoverSigner(messageHash, _senderSignature);
        require(senderAccount == sender, "Sender signature must be signed by the sender");
        address recipientAccount = _recoverSigner(messageHash, _recipientSignature);
        require(recipientAccount == recipient, "Recipient signature must be signed by the recipient");
        // Check the preimage and hash value one by one
        for(uint i = 0; i < _preimageList.length; i++) {
            bytes32 hash = keccak256(abi.encodePacked(_preimageList[i]));
            require(hash == _hashList[i], "Inconsistency between Hash List and Preimage List");
        }

        // Update all the information in the contract
        sequenceNum = _sequenceNum;
        senderBalance = _senderBalance;
        recipientBalance = _recipientBalance;
        expiration = 0;
    }

    // Try to close the channel
    function tryToClose() public {
        require(expiration == 0 || block.timestamp < expiration, "Channel closed");
        expiration = block.timestamp + 10;
    }

    // Withdrawal function, used to transfer the contract balance to an external private account
    function withdraw() public {
        require(expiration != 0 && block.timestamp > expiration, "Channel hasn't been closed");
        if (recipientBalance > 0) {
            recipient.transfer(recipientBalance);
        }
        if (senderBalance > 0) {
            sender.transfer(address(this).balance);
        }
    }

    // Recover signer address from _msgHash and _signature
    // _msgHash：message hash valueto
    // _signature：signature, using value pass since using the mload memory operation
    function _recoverSigner(bytes32 _msgHash, bytes memory _signature) internal pure returns (address) {
        // Check signature length, 65 is the standard length for r,s,v signature
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Currently only assembly can be used to obtain the values of r, s, v from the signature
        assembly {
            /*
            The first 32 bytes store the length of the signature (dynamic array storage rule)
            add(sig, 32) = sig's pointer + 32
            Equivalent to skipping the first 32 bytes of the signature
            mload(p) loads the next 32 bytes of data starting from memory address p
            */
            // Read the next 32 bytes after the length data
            r := mload(add(_signature, 0x20))
            // Read the next 32 bytes
            s := mload(add(_signature, 0x40))
            // Read the last byte
            v := byte(0, mload(add(_signature, 0x60)))
        }
        // Use ecrecover (global function): recover the signer address using msgHash and r, s, v
        return ecrecover(_msgHash, v, r, s);
    }
}