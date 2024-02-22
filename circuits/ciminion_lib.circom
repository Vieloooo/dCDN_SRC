pragma circom 2.0.3; 

include "./ciminion/ciminion_enc.circom"; 
include "./ciminion/ciminion_dec.circom"; 
include "./lib.circom";
template chunk_enc_tweak_64(){
    signal input MK_0;
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal input index; 
    signal input PT[64];
    signal output CT[64];
    // tweak the nonce 
    component nd = nonce_derive(); 
    nd.pre_nonce <== nonce;
    nd.r <== index;
    signal nonce_tweaked <== nd.post_nonce;
    component enc = CiminionEnc(32);
    enc.MK_0 <== MK_0;
    enc.MK_1 <== MK_1;
    enc.nonce <== nonce_tweaked;
    enc.IV <== IV;
    enc.PT <== PT;
    CT <== enc.CT;
}

template chunk_dec_tweak_64(){
    signal input MK_0;
    signal input MK_1;
    signal input nonce;
    signal input IV;
    signal input index; 
    signal input CT[64];
    signal output PT[64];
    // tweak the nonce 
    component nd = nonce_derive(); 
    nd.pre_nonce <== nonce;
    nd.r <== index;
    signal nonce_tweaked <== nd.post_nonce;
    component dec = CiminionDec(32);
    dec.MK_0 <== MK_0;
    dec.MK_1 <== MK_1;
    dec.nonce <== nonce_tweaked;
    dec.IV <== IV;
    dec.CT <== CT;
    PT <== dec.PT;
}