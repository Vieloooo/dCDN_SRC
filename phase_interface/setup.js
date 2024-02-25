const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);
const VXOR_Lib = require("../scripts/vxor.js"); 
/// generate secret key and a 254 bits hash, save the key to json in a local path 
const fs = require('fs');
const ciminionLib = require('../scripts/ciminion_key.js');
async function SETUP_prep(sk_path, secret_path){
    // generate a secret key
    const sk = ciminionLib.GenCiminionKey();
    // write the sk into a json file 
    const sk_json = JSON.stringify(sk);
    fs.writeFileSync(sk_path, sk_json);

    // generate a 254 bits hash 
    const secret = ciminionLib.randomScalar(Fr);
    if (secret >= Fr.p){
        console.log("error in secret generation");
    } 
    console.log("secret key: ", sk);
    console.log("secret hash: ", secret);
    // save secret to json 
    const secret_json = JSON.stringify(secret);
    fs.writeFileSync(secret_path, secret_json);
    return; 
}

/// load secret key and a 254 bits hash from local path, then generate vxor 

async function SETUP_Gen_VXOR(sk_path, secret_path, proof_path, pubSig_path ){
    // load the sk and secret from json 
    const sk = JSON.parse(fs.readFileSync(sk_path)); 
    const secret = JSON.parse(fs.readFileSync(secret_path)); 
    console.log(secret, typeof(secret));
    return await VXOR_Lib.VXOR_Gen(sk, secret, false, proof_path, pubSig_path)
}

/// Verify the setup vxor 
async function SETUP_Ver_VXOR(verify_key_path= "../keys/vxor_ver.json", proof_path , pubSig_path){
    await VXOR_Lib.VXOR_Ver(verify_key_path, proof_path, pubSig_path); 
}

module.exports = {
    SETUP_Gen_VXOR, 
    SETUP_prep,
    SETUP_Ver_VXOR, 
}