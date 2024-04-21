pragma circom 2.1.0;

include "./poseidon/poseidon.circom";


//a merkle layer with 8^N leaves
template LayerN(N){
    var total_gate = 8 ** (N-1); 
    signal input in[total_gate * 8];
    signal output out[total_gate]; 
    component poseidon[total_gate]; 
    for (var i = 0; i < total_gate; i++){
        poseidon[i] = Poseidon(8);
    }
    for(var i = 0; i < total_gate; i++){
        poseidon[i].inputs[0] <== in[8*i];
        poseidon[i].inputs[1] <== in[8*i+1];
        poseidon[i].inputs[2] <== in[8*i+2];
        poseidon[i].inputs[3] <== in[8*i+3];
        poseidon[i].inputs[4] <== in[8*i+4];
        poseidon[i].inputs[5] <== in[8*i+5];
        poseidon[i].inputs[6] <== in[8*i+6];
        poseidon[i].inputs[7] <== in[8*i+7];
        
        out[i] <== poseidon[i].out;
    }
}

// a 8-merkle tree with 512 leaves, which means it has 3 layers 

template hash512(){
    signal input in[512]; 
    signal output out;
    component l3 = LayerN(3);
    component l2 = LayerN(2);
    component l1 = LayerN(1);
    // write them together 
    for(var i = 0; i < 512; i++){
        l3.in[i] <== in[i];
    }
    for(var i = 0; i < 64; i++){
        l2.in[i] <== l3.out[i];
    }
    for(var i = 0; i < 8; i++){
        l1.in[i] <== l2.out[i];
    }
    out <== l1.out[0];
}

template hash64(){
    signal input in[64]; 
    signal output out;
    component l2 = LayerN(2);
    component l1 = LayerN(1);
    // write them together
    for(var i = 0; i < 64; i++){
        l2.in[i] <== in[i];
    }
    for(var i = 0; i < 8; i++){
        l1.in[i] <== l2.out[i];
    }
    out <== l1.out[0];
}


//a merkle layer with M^N leaves, a layer of N M-to-1 hash functions
// M < 15 
// This circuit take M^n number as input, then it will take these numbers to N groups, each group has M numbers, then it will hash these M numbers to 1 number.
template LayerMN(M, N){
    var total_gate = M ** (N-1); 
    signal input in[total_gate * M];
    signal output out[total_gate]; 
    component poseidon[total_gate]; 
    for (var i = 0; i < total_gate; i++){
        poseidon[i] = Poseidon(M);
    }
    for(var i = 0; i < total_gate; i++){
        for(var j = 0; j < M; j++){
            poseidon[i].inputs[j] <== in[M*i+j];
        }
        
        out[i] <== poseidon[i].out;
    }
}

template hash128(){
    signal input in[128]; 
    signal output out;
    component h64 = hash64();
    component l1 = LayerMN(2, 7);
    // wire all input to l1 
    for(var i = 0; i < 128; i++){
        l1.in[i] <== in[i];
    }
    // wire l1 to h64
    for(var i = 0; i < 64; i++){
        h64.in[i] <== l1.out[i];
    }
    out <== h64.out;
}

template hash256(){
    signal input in[256]; 
    signal output out;
    component h64 = hash64();
    component l1 = LayerMN(4, 4);
    // wire all input to l1
    for(var i = 0; i < 256; i++){
        l1.in[i] <== in[i];
    }
    // wire l1 to h128
    for(var i = 0; i < 64; i++){
        h64.in[i] <== l1.out[i];
    }
}

template hash1024(){
    signal input in[1024]; 
    signal output out;
    component h256 = hash256();
    component l1 = LayerMN(4, 5);
    // wire all input to l1
    for(var i = 0; i < 1024; i++){
        l1.in[i] <== in[i];
    }
    // wire l1 to h512 
    for(var i = 0; i < 256; i++){
        h256.in[i] <== l1.out[i];
    }
}

template hash2048(){
    signal input in[2048]; 
    signal output out;
    component h1 = hash512();
    component h2 = hash512();
    component h3 = hash512();
    component h4 = hash512();
    // write input to 4 h 
    for (var i = 0 ; i< 512; i++){
        h1.in[i] <== in[i];
        h2.in[i] <== in[i+512];
        h3.in[i] <== in[i+1024];
        h4.in[i] <== in[i+1536];
    }
    component h4to1 = Poseidon(4);
    h4to1.inputs[0] <== h1.out;
    h4to1.inputs[1] <== h2.out;
    h4to1.inputs[2] <== h3.out;
    h4to1.inputs[3] <== h4.out;
    out <== h4to1.out;
    
}