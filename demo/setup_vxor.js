const vxorLib = require("../scripts/vxor.js");

const fs = require('fs');

const cipherLib = require("../scripts/ciphers.js");

const ciminionLib = require("../scripts/ciminion_key.js");

const SETUPLib = require("../phase_interface/setup.js")
async function  run(){

    console.log("P generate secret key and a 254 bits secret which mask the key");

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

    console.log("----------------------------------");
    console.log("C receive the vxor proofs  and verify them");

    console.log("Verify the vxor from P");
    const res1 = await vxorLib.VXOR_Ver(verify_key_path= "../keys/vxor_ver.json", proof_path=proof_path_P, pubSig_path=pubSig_path_P);

    // ver the vxor from R
    console.log("Verify the vxor from R");
    const res2 = await vxorLib.VXOR_Ver(verify_key_path= "../keys/vxor_ver.json", proof_path=proof_path_R, pubSig_path=pubSig_path_R);
    console.log("P and R's vxor proofs are verified: ", res1, res2);
    console.log("----------------------------------");
    console.log("Assume C make the payment, get the secret from P and R, then get the keys");
    // pubsig[0] is c1, pubsig[1] is c2, pubsig[2] is c3
    const s_P = JSON.parse(fs.readFileSync(secret_path_P));
    const s_R = JSON.parse(fs.readFileSync(secret_path_R));
    console.log("C get P's secret:  ");
    console.log(s_P);
    console.log("C get R's secret:"); 
    console.log(s_R);
    // load voxr pubsig 
    const pub_P = JSON.parse(fs.readFileSync(pubSig_path_P));
    const c1_P = pub_P[0];
    const c2_P = pub_P[1];
    const c3_P = pub_P[2];
    const pub_R = JSON.parse(fs.readFileSync(pubSig_path_R));
    const c1_R = pub_R[0];
    const c2_R = pub_R[1];
    const c3_R = pub_R[2];
    //console.log(c1_P, c2_P, c3_P, typeof(c1_P),s_P, typeof(s_P));
    // rev vxor 
    const rev_P =await vxorLib.VXOR_Rev(c1_P, c2_P, c3_P, s_P);
    const rev_R = await vxorLib.VXOR_Rev(c1_R, c2_R, c3_R, s_R);
    console.log("C recover the keys from vxor and secret:");
    
    console.log("P's recovered key:\n", "MK_0: ", rev_P[0], "\nMK_1: ", rev_P[1], "\nnonce: ", rev_P[2]);
    console.log("R's recovered key:\n", "MK_0: ", rev_R[0], "\nMK_1: ", rev_R[1], "\nnonce: ", rev_R[2]);

}

run().then(()=> process.exit(0))