// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./pof_ver_origin.sol"; 
import "@openzeppelin/contracts/utils/Strings.sol";
/*
Minimium Judge Interface: 
- add content: any user can submit a pair(message(string), sha256 merkle root (uint256)) onchain. the judge will store this pair hash -> (msg, sha256, address) in a map. return the hash of the pair. 
- remove content: any user can remove a pair from the map. the caller's address must match the address stored in the map. 
- join network: any user can join the network by transfer at lease "x" ether to the contract. judge maintain a map (address => (balance, leaveBlockHeight)). the default leaveBlockHeight is 0.
- leave network: any user can leave the network by submitting a leave review to the contract. the contract will lock the user's deposit for "y" blocks, and after "y" blocks, the user can withdraw the deposit. the judge will update the map (address => (balance, leaveBlockHeight)) to the current block height. 
- withdraw deposit: any user can withdraw the deposit after "y" blocks after leave. judge will check the leaveBlockHeight to determine if the user can withdraw the deposit.
- proof of fraud: any user can submit a proof of fraud, which contains (commitment, address, zk_pof). the judge will verify the proof of fraud first. if the proof is valid, the judge will slash the deposit of the address and transfer the z percent of deposit to the submitter.
*/

contract MinimumJudge {
    struct Content {
        string message;
        uint256 sha256MerkleRoot;
        address userAddress;
    }

    struct User {
        uint256 balance;
        uint256 leaveBlockHeight;
    }

    // Minimum deposit to join network
    uint256 public constant x = 1 ether;
    // Lock period for leaving the network
    uint256 public constant y = 100;
    // Percentage of deposit slashed for fraud (in basis points, 10000 bp = 100%)
    uint256 public constant z = 5000; // 50% for example

    mapping(bytes32 => Content) public contents;
    mapping(address => User) public users;
    Groth16Verifier public PoFVerify;

    constructor(address zkVerifyAddress) {
        PoFVerify = Groth16Verifier(zkVerifyAddress);
    }

    function addContent(string memory message, uint256 sha256MerkleRoot) external returns (bytes32) {
        bytes32 contentHash = keccak256(abi.encodePacked(message, sha256MerkleRoot));
        contents[contentHash] = Content(message, sha256MerkleRoot, msg.sender);
        return contentHash;
    }

    function removeContent(bytes32 contentHash) external {
        require(contents[contentHash].userAddress == msg.sender, "Unauthorized");
        delete contents[contentHash];
    }

    function joinNetwork() external payable {
        require(msg.value >= x, "Insufficient Ether sent");
        // the new user must have not join the network before 
        require(users[msg.sender].balance == 0, "Already part of the network");
        users[msg.sender].balance += msg.value;
        users[msg.sender].leaveBlockHeight = 0;
    }

    function leaveNetwork() external {
        require(users[msg.sender].balance >= x, "Not part of the network");
        users[msg.sender].leaveBlockHeight = block.number + y;
    }

    function withdrawDeposit() external {
        require(users[msg.sender].balance >= 0, "No deposit");
        require(block.number > users[msg.sender].leaveBlockHeight && block.number != 0 , "Deposit locked");
        uint256 amount = users[msg.sender].balance;
        users[msg.sender].balance = 0;
        payable(msg.sender).transfer(amount);
    }
    // _pubSignals[0] is the hash of secret key h(MK0, MK1, nonce); _pubSignals[1] is the hash of the ciphertext chunk h(ct), _pubSignals[2] is the hash of the plaintext chunk h(pt), _pubSignals[3] is the index of the chunk. all number are in hex format 
    function proofOfFraud(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[4] calldata _pubSignals, uint  originPTHash, address cheater_addr, uint8 _v, bytes32 _r, bytes32 _s) external {
        // check if the cheater_addr has enough deposit
        require(users[cheater_addr].balance >= x, "Not part of the network");
        // check the origin originPTHash != _pubSignals[2]
        require(originPTHash != _pubSignals[2], "Invalid proof: the hash must be different");
        // build the message 
        // msg = "{orignPTHash, _pubSignals[1], _pubSignals[0], _pubSignals[3]}"
        // all uint will convert to a decimal string 
        string memory h_prev = Strings.toString(originPTHash);
        string memory h_next = Strings.toString(_pubSignals[1]);
        string memory h_secret = Strings.toString(_pubSignals[0]);
        string memory index = Strings.toString(_pubSignals[3]);
        // concatenate the message 
        string memory message = string(abi.encodePacked("{", h_prev, ", ", h_next, ", ",h_secret,", ", index , "}"));
        // check the signature 
        require(verifySignature(message, _v, _r, _s, cheater_addr), "Invalid signature");
        // verify the pof 
        require(PoFVerify.verifyProof(_pA, _pB, _pC, _pubSignals), "Invalid proof");
        // slash the deposit and transfer the z percent to the submitter
        uint256 amount = users[cheater_addr].balance;
        users[cheater_addr].balance = 0;
        uint256 reward = amount * z / 10000;
        payable(msg.sender).transfer(reward);

    }

    /* 此函数用于生成消息的以太坊特定签名哈希
     * @param _message: 要签名的原始消息
     * @return 以太坊特定的签名哈希
     */
    function getMessageHash(string memory _message) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }

    /* 用于恢复签名者的地址
     * @param _messageHash: 消息的哈希
     * @param _v: 签名的v值
     * @param _r: 签名的r值
     * @param _s: 签名的s值
     * @return 签名者的地址
     */
    function recoverSigner(bytes32 _messageHash, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        return ecrecover(_messageHash, _v, _r, _s);
    }

    /* 验证消息签名
     * @param _originalMessage: 签名的原始消息
     * @param _v: 签名的v值
     * @param _r: 签名的r值
     * @param _s: 签名的s值
     * @param _expectedSigner: 预期的签名者地址
     * @return 签名是否有效
     */
    function verifySignature(string memory _originalMessage, uint8 _v, bytes32 _r, bytes32 _s, address _expectedSigner) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_originalMessage);
        address signer = recoverSigner(messageHash, _v, _r, _s);
        return signer == _expectedSigner;
    }
}
/*
    deploy cost: 2411513
    
*/