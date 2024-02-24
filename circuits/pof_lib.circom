pragma circom 2.0.3; 
include "./lib.circom"; 

/*
Inputs: 
    - sk
    - h_sk
    - r 
    - CTC[r]
intemediate: 
    - ptc_r
Output: 
    - hash(CTC[r])
*/

template PoF64(){
    signal input MK_0; 
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal output h_sk; 
    signal input r; 
    signal input CTC_r[64]; 
    signal output h_CTC; 
    signal output h_PTC; 

    // check sk 
    component check = sk_hash();
    check.MK_0 <== MK_0;
    check.MK_1 <== MK_1;
    check.nonce <== nonce;
     h_sk <== check.h_sk;

    // derive 
    component nonce_derive = nonce_derive();
    nonce_derive.pre_nonce <== nonce;
    nonce_derive.r <== r;
    signal nonce_derive_out <== nonce_derive.post_nonce; 

    // dec CTC_r 
    component dec = chunk_dec64(); 
    dec.MK_0 <== MK_0;
    dec.MK_1 <== MK_1;
    dec.nonce <== nonce_derive_out;
    dec.IV <== IV;
    dec.CT <== CTC_r;

    // hash 
    component hash = hash64();
    hash.in <== dec.PT;

    // output
    h_PTC <== hash.out;

    // calcuate the CTC's hash 
    component hash_CTC = hash64();
    hash_CTC.in <== CTC_r;
    h_CTC <== hash_CTC.out;
}