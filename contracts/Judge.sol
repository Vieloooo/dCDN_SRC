// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

struct ZKParam{
    uint[2] _pA;
    uint[2][2] _pB;
    uint[2] _pC;
}
interface Groth16ZKP{
    function verifyProof(ZKParam calldata _pp, uint[4] calldata _pubSignals)external view returns (bool); 
}

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
    // zkp addr 
    address public zkpAddr; 
    // Minimum deposit to join network
    uint256 public constant x = 1 ether;
    // Lock period for leaving the network
    uint256 public constant y = 100;
    // Percentage of deposit slashed for fraud (in basis points, 10000 bp = 100%)
    uint256 public constant z = 5000; // 50% for example

    mapping(bytes32 => Content) public contents;
    mapping(address => User) public users;
    //Groth16Verifier public PoFVerify;

    // log 
    event TestPoF(bool if_pass_pof); 
    constructor(address zkVerifyAddress) {
       zkpAddr = zkVerifyAddress; 
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
    function proofOfFraud(ZKParam calldata _pp, uint[4] calldata _pubSignals, string memory originPTHash,  uint8 _v, bytes32 _r, bytes32 _s, address cheater_addr) external {
        // check if the cheater_addr has enough deposit
        require(users[cheater_addr].balance >= x, "Not part of the network");

        // check the origin originPTHash != _pubSignals[2]
        // convert the _pubSignals[2] to string first 
        string memory h_pt = Strings.toString(_pubSignals[2]);
        require(keccak256(abi.encodePacked(h_pt)) != keccak256(abi.encodePacked(originPTHash)), "Invalid originPTHash");
        // msg = "{orignPTHash, _pubSignals[1], _pubSignals[0], _pubSignals[3]}"
        string memory h_prev = originPTHash; 
        string memory h_next = Strings.toString(_pubSignals[1]);
        string memory h_secret = Strings.toString(_pubSignals[0]);
        string memory index = Strings.toString(_pubSignals[3]); 
        string memory message = string(abi.encodePacked("{", h_prev, ", ", h_next, ", ",h_secret,", ", index , "}"));
        
        require(verifySignature(message, _v, _r, _s, cheater_addr), "Invalid signature");
        // verify the pof 
        bool  res = Groth16ZKP(zkpAddr).verifyProof(_pp, _pubSignals); 
        emit TestPoF(res); 
        require(res, "Invalid proof");
        // slash the deposit and transfer the z percent to the submitter
        uint256 amount = users[cheater_addr].balance;
        users[cheater_addr].balance = 0;
        uint256 reward = amount * z / 10000;
        payable(msg.sender).transfer(reward);

    }

    function verifySignature(string memory _originalMessage, uint8 _v, bytes32 _r, bytes32 _s, address _expectedSigner) public returns (bool) {
            bytes32 msgHash = keccak256(abi.encodePacked(_originalMessage)); 
            address signer = ecrecover(msgHash, _v, _r, _s);
            return signer == _expectedSigner;
        }
}
/*
    // remix VM: (Shanghai)
    Sol compiler: 0.8.24 
    (gas, tx gas )
    PoF deploy:  431576 
    Judge deploy: 	1989612
    PoF zkp:  208946 
    Judge PoF: 		290797
    add content: 90924
    remove content:  30159
    Join network:  46175
    Leave network: 	28783
    Withdraw deposit: 	25966


    
*/

/*
Proof of Fraud call example: 

// wraped: proper commitment and proper zkp 
[
    ["0x25d52ea0451461ba065607a754c9f5839a68ed4a118ac02c1079c3817919d407", "0x29c14c0aacedff02e633314ef1d556ae245a7fbbf6e89f761d037fe24381b661"],[["0x2a0ec0a2691624149153379bd649e7c1c6e336ebada52fba2ab23521d3f2c29b", "0x07e5ea3ffef342b57b6ea153c616e5d2cb1ff975693c0fa8f543f2a7e516e151"],["0x0558dbdb7dbe4ff2eeecba7e2466369f759d5fc35359470cd3bd3fd51f5e6a9c", "0x2e1eba46475d68b7e777350d15e8952415bbc050cb4d76ce28166d1aa11d2bab"]],["0x268ea8b760eb13b198adf36433e9fcffc0bf4d3b4a0044208a2758c7cc543337", "0x1677b747752a9fe3f3dbed036962459a4188c3ea9a30858e657484631d5a41f0"]
], 
["0x1bd9813210f236586f272b1a92a10faf60419adb6b7df7db799061d49be7c69c","0x21400f0828a017b20700e3347618cd6cb7b42ce326d37d141d9bf8c23e3a3981","0x1b5d1dc00b2915b3233ca8ecc2644f51d93a265c6056392a6b9d995b0ef7c17e","0x0000000000000000000000000000000000000000000000000000000000000000"], 
"12376969016901735748234494228761607566577764237603762757423708437165437862270", 
"27", 
"0x6485f90af21b650e698f8f4a6cd5dc3d82cc750592dc479020ef665b255b7290", 
"0x7a83c5abd7575e89ff47a4d2131a4934da7793c46bdd56ea8c9331d1873c0bea", 
"0xb0Df653BB211dEf394Fc32A1074d2e21d15684F8"

// bad commitment (tweak the input hash and commitment on something wrong)
[
    ["0x25d52ea0451461ba065607a754c9f5839a68ed4a118ac02c1079c3817919d407", "0x29c14c0aacedff02e633314ef1d556ae245a7fbbf6e89f761d037fe24381b661"],[["0x2a0ec0a2691624149153379bd649e7c1c6e336ebada52fba2ab23521d3f2c29b", "0x07e5ea3ffef342b57b6ea153c616e5d2cb1ff975693c0fa8f543f2a7e516e151"],["0x0558dbdb7dbe4ff2eeecba7e2466369f759d5fc35359470cd3bd3fd51f5e6a9c", "0x2e1eba46475d68b7e777350d15e8952415bbc050cb4d76ce28166d1aa11d2bab"]],["0x268ea8b760eb13b198adf36433e9fcffc0bf4d3b4a0044208a2758c7cc543337", "0x1677b747752a9fe3f3dbed036962459a4188c3ea9a30858e657484631d5a41f0"]
], 
["0x1bd9813210f236586f272b1a92a10faf60419adb6b7df7db799061d49be7c69c","0x21400f0828a017b20700e3347618cd6cb7b42ce326d37d141d9bf8c23e3a3981","0x1b5d1dc00b2915b3233ca8ecc2644f51d93a265c6056392a6b9d995b0ef7c17e","0x0000000000000000000000000000000000000000000000000000000000000000"], 
"12376969016901735748234494228761607566577764237603762757423708437165437862272", 
"27", 
"0xa510b6221c797016fc281259743d300a1f4d57e4a7e08f989fe043d0e6c79249", 
"0x0c2baae4da8ce8f5771b4c1271982c658166d7c23067aa2e92a1b7bee9eb17fe", 
"0xb0Df653BB211dEf394Fc32A1074d2e21d15684F8"

*/