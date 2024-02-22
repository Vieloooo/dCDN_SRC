pragma circom 2.1.0; 

include "./circomlib/sha256/sha256.circom";

template wrapper(N){
    signal input in[N]; 
    signal output out[256]; 
    signal {binary} in_w[N] <== in; 
    component sha256 = Sha256(N);
    sha256.in <== in_w;
    out <== sha256.out;
}
// inputs is 256 bits 
component main = wrapper(8);