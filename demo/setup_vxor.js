const vxorLib = require("../scripts/vxor.js");

const fs = require('fs');

const cipherLib = require("../scripts/ciphers.js");

const ciminionLib = require("../scripts/ciminion_key.js");

const SETUPLib = require("../phase_interface/setup.js")
console.log("P generate secret key and a 254 bits secret which mask the key");
async function  run(){


    const sk_path_P = "./P/sk.json";
    const secret_path_P = "./P/secret.json";
    await SETUPLib.SETUP_prep(sk_path_P, secret_path_P);
    
    console.log("P generate vxor and proof");
    const proof_path_P = "./P/proof_vxor.json";
    const pubSig_path_P = "./P/pubSig_vxor.json";

    await SETUPLib.SETUP_Gen_VXOR(sk_path_P, secret_path_P, proof_path_P, pubSig_path_P);

    console.log("P send the vxor and proof to C");
    console.log("----------------------------------");
    console.log("R generate secret key and a 254 bits secret which mask the key");

    const sk_path_R = "./R/sk.json";
    const secret_path_R = "./R/secret.json";
    await SETUPLib.SETUP_prep(sk_path_R, secret_path_R);

    console.log("R generate vxor and proof");
    const proof_path_R = "./R/proof_vxor.json";
    const pubSig_path_R = "./R/pubSig_vxor.json";

    await SETUPLib.SETUP_Gen_VXOR(sk_path_R, secret_path_R, proof_path_R, pubSig_path_R);

    console.log("R send the vxor and proof to C");

}

run().then(()=> process.exit(0))