// encrypt 64 numbers(plaintext) using a key set on Ciminion
pragma circom 2.0.3; 

include "./ciminion/ciminion_enc.circom"; 

component main = CiminionEnc(32); 
