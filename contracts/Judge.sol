// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//import "./PoF.sol"; 
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
    struct Sig{
        uint8 _v; 
        bytes32 _r;
        bytes32 _s;
    }
    // Enforceable A-HTLC 
    struct Challenge {
        uint256 T; // Block height (timestamp)
        bytes32[] H; // Ordered list of hashes
        bytes32 h0; // A single hash
        address[] ADDR; // List of addresses
    }

    struct Ch2 {
        uint256 st; // start time 
        bytes32[] H; // Ordered list of hashes
        address[] ADDR; // List of addresses
        uint256 idx;    // the one to be challenged start from n -> 1 
    }

    // Challenge list 
    mapping(bytes32 => Ch2) public challengeList; 
    uint256 public constant inverval = 2; 
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
        users[msg.sender].balance = msg.value;
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
    function pome(ZKParam calldata _pp, uint[4] calldata _pubSignals, string memory originPTHash,  uint8 _v, bytes32 _r, bytes32 _s, address cheater_addr) external {
        // check if the cheater_addr has enough deposit
        //require(users[cheater_addr].balance >= x, "Not part of the network");

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
    function pomm(bytes32 _hs, bytes32 _hk, bytes32 _xor, bytes32 _secret, uint8 _v, bytes32 _r, bytes32 _s, address _addr) external {
        string memory message = string(abi.encodePacked("{", _hs, _hk, _xor,"}"));
        bytes32 msgHash = keccak256(abi.encodePacked(message)); 
        // check the signer
        address signer = ecrecover(msgHash, _v, _r, _s);
        require(signer == _addr, "Invalid signature");
        // check h(s) and h(k)
        bytes32 hs = keccak256(abi.encodePacked(_secret));
        require(_hs == hs, "secret and hash don't match");
        // compute k
        bytes32 k = _secret ^ _xor;
        bytes32 hk = keccak256(abi.encodePacked(k));
        // slash the node
        if (hk != _hk) {
            uint256 amount = users[_addr].balance;
            users[_addr].balance = 0;
            uint256 reward = amount * z / 10000;
            payable(msg.sender).transfer(reward);
        } 
    }

    function verifySignature(string memory _originalMessage, uint8 _v, bytes32 _r, bytes32 _s, address _expectedSigner) public returns (bool) {
            bytes memory prefix = "\x19Ethereum Signed Message:\n32"; 
            bytes32 msgHash = keccak256(abi.encodePacked( _originalMessage)); 
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msgHash));
            address signer = ecrecover(prefixedHash, _v, _r, _s);
            return signer == _expectedSigner;
    }

    function verifyRawSignature(bytes32 msgHash, uint8 _v, bytes32 _r, bytes32 _s, address _expectedSigner) public returns (bool) {
            bytes memory prefix = "\x19Ethereum Signed Message:\n32"; 
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msgHash));
            address signer = ecrecover(msgHash, _v, _r, _s);
            return signer == _expectedSigner;
    }
    function HashCh(Challenge memory Ch) public pure returns(bytes32) {
        bytes32 h1 = keccak256(abi.encodePacked(Ch.T)); 
        bytes32 h2 = keccak256(abi.encodePacked(h1,Ch.h0 )); 
        bytes32 h3 = keccak256(abi.encodePacked(h2, Ch.H));
        bytes32 h4 = keccak256(abi.encodePacked(h3, Ch.ADDR));
        return h4; 
    }
    function EnfStart( Challenge calldata Ch, Sig[] calldata sigs, bytes calldata s0) external {
        // Ch has never been uploaded before 
        // cal the hash of Ch 
        bytes32 ct = HashCh(Ch); 
        // check if ct in challenge lists 
        require(challengeList[ct].st == 0, "Already challenged");
        require(block.number <= Ch.T, "Challenge Timeout");
        bytes32 h02 = keccak256(abi.encodePacked(s0));
        require(h02 == Ch.h0, "invalid sync secret"); 
        // check if sig in sigs sign ch 
        // length of sigs 
        uint256 sig_len = sigs.length ;
        require(Ch.ADDR.length == sig_len, "invalid signatures"); 
        for (uint256 i=0 ; i < sig_len; i++){
            require(verifyRawSignature(ct, sigs[i]._v, sigs[i]._r,sigs[i]._s, Ch.ADDR[i]) , "Invalid signatures"); 
        }
        // set idx
        challengeList[ct].idx = sig_len - 1;
        challengeList[ct].H = Ch.H; 
        challengeList[ct].st = block.number ;
        challengeList[ct].ADDR = Ch.ADDR ;
    }

    function EnfLog(bytes32 ct2, bytes calldata si) external {
        bytes32 hi = challengeList[ct2].H[challengeList[ct2].idx - 1]; 
        // check timeout : challengeList[ct2].st + (addr.length - idx) * interval > current block height 
        uint256 id =  challengeList[ct2].idx - 1; 
        require(id > 0, "Invalid index");
        require(challengeList[ct2].st + (challengeList[ct2].ADDR.length - id + 1) * inverval > block.number ,"Invalid responce" );
        // check revealed secrets 
        require(hi == keccak256(abi.encodePacked(si)),"Invalid secrets");
        challengeList[ct2].idx = id; 
    }
    function EnfPunish(bytes32 ct2) external {
        // require idx != 0 
        require(challengeList[ct2].idx != 0, "Not Challenged");
        // challengeList[ct2].st + (addr.length - idx) * interval < current block height 
        require(challengeList[ct2].st + (challengeList[ct2].ADDR.length - challengeList[ct2].idx - 1) * inverval < block.number ,"Invalid challenge" );
        address cheater_addr = challengeList[ct2].ADDR[challengeList[ct2].idx];
        // slash the deposit and transfer the z percent to the submitter
        uint256 amount = users[cheater_addr].balance;
        users[cheater_addr].balance = 0;
        uint256 reward = amount * z / 10000;
        address refunder = challengeList[ct2].ADDR[0]; 
        payable(refunder).transfer(reward);
        challengeList[ct2].idx = 0; 
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