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

    component n2b_1 = Num2Bits_strict(); 
    component n2b_2 = Num2Bits_strict();
    n2b_1.in <== a; 
    n2b_2.in <== b;
    signal {binary} a_bits[254] <== n2b_1.out;
    signal {binary} b_bits[254]  <== n2b_2.out;

    signal {binary} c_bits[254];
    for (var i = 0; i < 254; i ++ ){
        c_bits[i] <== a_bits[i] +  b_bits[i] - 2 * a_bits[i] * b_bits[i];
    }
    component b2n = Bits2Num_strict();
    b2n.in <== c_bits;
    c <== b2n.out;

}
template VXOR_Rev(){
    signal input c1; 
    signal input c2;
    signal input c3;
    signal input secret; 
    signal output MK_0; 
    signal output MK_1; 
    signal output nonce; 
    component H1 = Poseidon(2); 
    component H2 = Poseidon(2); 
    H1.inputs[0] <== secret;
    H1.inputs[1] <== 1;
    H2.inputs[0] <== secret;
    H2.inputs[1] <== 2;

    signal mask1 <== H1.out; 
    signal mask2 <== H2.out;
    component xor1 = OP_XOR(); 
    xor1.a <== c1;
    xor1.b <== secret;
    MK_0 <== xor1.c;
    component xor2 = OP_XOR();
    xor2.a <== c2;
    xor2.b <== mask1;
    MK_1 <== xor2.c;
    component xor3 = OP_XOR();
    xor3.a <== c3;
    xor3.b <== mask2;
    nonce <== xor3.c;
} 

component main = VXOR_Rev();