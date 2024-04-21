pragma circom 2.0.3; 
include "./lib.circom"; 
include "./ciminion/ciminion_enc.circom";
include "./poseidon_recursive.circom";
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

template PoF128(){
    signal input MK_0; 
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal output h_sk; 
    signal input r; 
    signal input CTC_r[128]; 
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
    component dec = CiminionDec(64); 
    dec.MK_0 <== MK_0;
    dec.MK_1 <== MK_1;
    dec.nonce <== nonce_derive_out;
    dec.IV <== IV;
    dec.CT <== CTC_r;

    // hash 
    component hash = hash128();
    hash.in <== dec.PT;

    // output
    h_PTC <== hash.out;

    // calcuate the CTC's hash 
    component hash_CTC = hash128();
    hash_CTC.in <== CTC_r;
    h_CTC <== hash_CTC.out;
}

template PoF256(){
    signal input MK_0; 
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal output h_sk; 
    signal input r; 
    signal input CTC_r[256]; 
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
    component dec = CiminionDec(128); 
    dec.MK_0 <== MK_0;
    dec.MK_1 <== MK_1;
    dec.nonce <== nonce_derive_out;
    dec.IV <== IV;
    dec.CT <== CTC_r;

    // hash 
    component hash = hash256();
    hash.in <== dec.PT;

    // output
    h_PTC <== hash.out;

    // calcuate the CTC's hash 
    component hash_CTC = hash256();
    hash_CTC.in <== CTC_r;
    h_CTC <== hash_CTC.out;
}

template PoF512(){
    signal input MK_0; 
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal output h_sk; 
    signal input r; 
    signal input CTC_r[512]; 
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
    component dec = CiminionDec(256); 
    dec.MK_0 <== MK_0;
    dec.MK_1 <== MK_1;
    dec.nonce <== nonce_derive_out;
    dec.IV <== IV;
    dec.CT <== CTC_r;

    // hash 
    component hash = hash512();
    hash.in <== dec.PT;

    // output
    h_PTC <== hash.out;

    // calcuate the CTC's hash 
    component hash_CTC = hash512();
    hash_CTC.in <== CTC_r;
    h_CTC <== hash_CTC.out;
}

template PoF1024(){
    signal input MK_0; 
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal output h_sk; 
    signal input r; 
    signal input CTC_r[1024]; 
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
    component dec = CiminionDec(512); 
    dec.MK_0 <== MK_0;
    dec.MK_1 <== MK_1;
    dec.nonce <== nonce_derive_out;
    dec.IV <== IV;
    dec.CT <== CTC_r;

    // hash 
    component hash = hash1024();
    hash.in <== dec.PT;

    // output
    h_PTC <== hash.out;

    // calcuate the CTC's hash 
    component hash_CTC = hash1024();
    hash_CTC.in <== CTC_r;
    h_CTC <== hash_CTC.out;
}

template PoF2048(){
    signal input MK_0; 
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal output h_sk; 
    signal input r; 
    signal input CTC_r[2048]; 
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
    component dec = CiminionDec(1024); 
    dec.MK_0 <== MK_0;
    dec.MK_1 <== MK_1;
    dec.nonce <== nonce_derive_out;
    dec.IV <== IV;
    dec.CT <== CTC_r;

    // hash 
    component hash = hash2048();
    hash.in <== dec.PT;

    // output
    h_PTC <== hash.out;

    // calcuate the CTC's hash 
    component hash_CTC = hash2048();
    hash_CTC.in <== CTC_r;
    h_CTC <== hash_CTC.out;
}