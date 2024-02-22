pragma 2.0.3; 

include "./poseidon/poseidon.circom"; 

template VXOR(){
    signal input MK_0; 
    signal input MK_1; 
    signal input nonce; 
    signal input secret; 
    signal input 