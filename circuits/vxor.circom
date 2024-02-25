pragma circom 2.0.3; 

include "./poseidon/poseidon.circom";
include "./circomlib/bitify.circom"; 
include "./hash_sha256_BN.circom";
/* 
    c1 = MK_0 xor secret 
    c2 = MK_1 xor poseidon_2(secret, 1) 
    c3 = nonce xor poseidon_2(secret, 2)
    h_k = poseidon_3(MK_0, MK_1, nonce)
    h_s = sha256(secret) 
*/ 

template OP_XOR(){
    signal input a; 
    signal input b; 
    signal output c; 

    component n2b_1 = Num2Bits(256); 
    component n2b_2 = Num2Bits(256);
    n2b_1.in <== a; 
    n2b_2.in <== b;
    signal {binary} a_bits[256] <== n2b_1.out;
    signal {binary} b_bits[256]  <== n2b_2.out;

    signal {binary} c_bits[254];
    for (var i = 0; i < 254; i ++ ){
        c_bits[i] <== a_bits[i] +  b_bits[i] - 2 * a_bits[i] * b_bits[i];
    }
    component b2n = Bits2Num(254);
    b2n.in <== c_bits;
    c <== b2n.out;

}
template VXOR(){
    signal input MK_0; 
    signal input MK_1; 
    signal input nonce; 
    signal input secret; 
    signal output c1; 
    signal output c2;
    signal output c3;
    signal output h_k; 
    signal output h_s[256]; 
    component H1 = Poseidon(2); 
    component H2 = Poseidon(2); 
    component H3 = Poseidon(3); 
    H1.inputs[0] <== secret;
    H1.inputs[1] <== 1;
    H2.inputs[0] <== secret;
    H2.inputs[1] <== 2;
    H3.inputs[0] <== MK_0;
    H3.inputs[1] <== MK_1;
    H3.inputs[2] <== nonce;

    signal mask1 <== H1.out; 
    signal mask2 <== H2.out;
    h_k <== H3.out; 
    component xor1 = OP_XOR(); 
    xor1.a <== MK_0;
    xor1.b <== secret;
    c1 <== xor1.c;
    component xor2 = OP_XOR();
    xor2.a <== MK_1;
    xor2.b <== mask1;
    c2 <== xor2.c;
    component xor3 = OP_XOR();
    xor3.a <== nonce;
    xor3.b <== mask2;
    c3 <== xor3.c;

    // hash the secret 
    component sha256BN = sha256_BN();
    sha256BN.in <== secret;
    h_s <== sha256BN.out;
} 

component main = VXOR(); 
