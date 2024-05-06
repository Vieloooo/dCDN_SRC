// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MinimumJudge} from "./Judge.sol";
import "forge-std/console.sol";

contract MinimumJudgeTest is Test {
    MinimumJudge judge;
    address alice;
    uint256 alicePk;
    address bob;
    uint256 bobPk;
    address carol;
    uint256 carolPk;
    bytes s_sync; 
    bytes s0;
    bytes s1 ;
    bytes32 h0; 
    bytes32 h1 ;
    bytes32 hs; 
     bytes32 hch; 
    MinimumJudge.Challenge Ch; 
    MinimumJudge.Sig[] sigs; 
    function setUp() public {
        ( alice,  alicePk) = makeAddrAndKey("alice");
        (bob,  bobPk) = makeAddrAndKey("bob");
        ( carol, carolPk) = makeAddrAndKey("carol");
        judge = new MinimumJudge(alice); 
        vm.deal(alice, 10 ether); 
        vm.deal(bob, 10 ether); 
        vm.deal(carol, 10 ether); 
        join(alice); 
        join(bob); 
        join(carol);
        vm.roll(10);
        
        s_sync = "s sync"; 
        s0 = "123";
        s1 = "456";
        h0 = keccak256(abi.encodePacked(s0)); 
        h1 = keccak256(abi.encodePacked(s1)); 
        hs = keccak256(abi.encodePacked(s_sync)); 
        bytes32[] memory H = new bytes32[](2);
        H[0] = h0;
        H[1] = h1;
        address[] memory addrs = new address[](3);
        addrs[0] = alice;
        addrs[1] = bob;
        addrs[2] = carol;
        // new a challenge 
        Ch = MinimumJudge.Challenge(100, H, hs, addrs);
        // sign this challenge 
        sigs = new MinimumJudge.Sig[](3);
        hch = HashCh(Ch);
        // alice's sig 
        (uint8 _v1, bytes32 _r1, bytes32 _s1) = vm.sign(alicePk, hch);
        sigs[0] = MinimumJudge.Sig(_v1, _r1, _s1);
        // bob's sig
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(bobPk, hch);
        sigs[1] = MinimumJudge.Sig(v2, r2, s2);
        // carol's sig
        (uint8 v3, bytes32 r3, bytes32 s3) = vm.sign(carolPk, hch);
        sigs[2] = MinimumJudge.Sig(v3, r3, s3);
        
    }
    function join(address addr) public{
        uint256 expectedBalance = 1 ether;
        // chanage user to addr 
        vm.prank(addr); 
        // Call the joinNetwork function
        judge.joinNetwork{value: expectedBalance}();
        // Get the user's balance from the contract
        (uint256 userBalance, uint256 height) = judge.users(addr);  

         // Print the user's balance
        //console.log("User balance is", userBalance);
    }
    function hashCh(MinimumJudge.Challenge memory c) public pure returns(bytes32) {
        bytes32 ha = keccak256(abi.encodePacked(c.T)); 
        bytes32 hb = keccak256(abi.encodePacked(ha,c.h0 )); 
        bytes32 hc = keccak256(abi.encodePacked(hb, c.H));
        bytes32 hd = keccak256(abi.encodePacked(hc, c.ADDR));
        return hd; 
    }
    function test_EnfStart() public {
        // construct ch 
        // Enforceable A-HTLC  
        
        judge.EnfStart(Ch, sigs, s_sync);
    }
    function HashCh(MinimumJudge.Challenge memory Ch) public pure returns(bytes32) {
        bytes32 h1 = keccak256(abi.encodePacked(Ch.T)); 
        bytes32 h2 = keccak256(abi.encodePacked(h1,Ch.h0 )); 
        bytes32 h3 = keccak256(abi.encodePacked(h2, Ch.H));
        bytes32 h4 = keccak256(abi.encodePacked(h3, Ch.ADDR));
        return h4; 
    }

    function test_response() public {
        judge.EnfStart(Ch, sigs, s_sync);
        vm.roll(1); 
        judge.EnfLog(hch, s1);
    }
    function test_punish() public{
        vm.roll(100); 
        judge.EnfPunish(hch); 
    }
}
