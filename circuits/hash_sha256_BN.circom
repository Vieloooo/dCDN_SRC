pragma circom 2.1.0; 

include "./circomlib/sha256/sha256.circom";
include "./circomlib/bitify.circom"; 
/*
    input is a BN-254 number, we convert this number to a 256 bits number and wire these 256 outputs to sha256 input.
*/
template sha256_BN(){
    signal input in; 
    signal output out[256]; 
    component num2bits = Num2Bits(254);
    num2bits.in <== in;
    signal {binary} in_bits[254] <== num2bits.out; 
    
    component sha256 = Sha256(254);
    sha256.in <== in_bits;
    out <== sha256.out;
}

//component main = sha256_BN(); 
