const fs = require("fs"); 
const wasm_tester = require("../circom_tester/index").wasm;

/// generate a proof of fraud
// inputs: ciphertext chunk, secret key, if_recompile
// add ".then()" to exit this process
async function PoF_Gen(ctc, sk, index, if_recompile = true, proof_path="./pof_proof.json", pubSig_path = "./pof_public.json"){
    // load the circuit 
    const cir = await wasm_tester("../circuits/pof.circom", {
        output: "../tmp",
        recompile: if_recompile,
    });
    // get the hash of of sk 
    const cipherLib = require("./ciphers.js");
    const h_sk = await cipherLib.HashKey(sk, true); 
    // build the input for the circuit
    const input = {
        MK_0: sk.MK_0,
        MK_1: sk.MK_1,
        nonce: sk.nonce,
        IV: sk.IV, 
        CTC_r: ctc,
        r: index, 

    }
    //console.log(h_sk, typeof(h_sk));
    // generate the witness
    const wtns = await cir.calculateWitness(input);
    // get the output from wtns 
    const output = await cir.getOutput(wtns, ["h_CTC", "h_PTC", "h_sk"]);
    // filter the h_CTC_r 
    const h_prev = output["h_CTC_r"];
    //.log("the source hash is:", h_prev);

    // generate proofs 
    const snarkjs = require("snarkjs");
    const cir_wasm_path = "../tmp/pof_js/pof.wasm";
    const final_zkey_path = "../keys/16_pof_1.zkey";
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(input, cir_wasm_path, final_zkey_path);
    // export the proof to json
    const proof_json = JSON.stringify(proof, null, 1);
    const pubSig_json = JSON.stringify(publicSignals, null, 1);
    // write json to files 
    fs.writeFileSync(proof_path, proof_json);
    fs.writeFileSync(pubSig_path, pubSig_json);
}

/// verify the proof of fraud
// inputs: verify_key_path, proof_path, pubSig_path
async function PoF_Ver(verify_key_path= "../keys/pof_ver.json", proof_path = "./pof_proof.json", pubSig_path="pof_public.json"){
    const snarkjs = require("snarkjs");
    const fs = require('fs');
    const vKey = JSON.parse(fs.readFileSync(verify_key_path));
    const proof = JSON.parse(fs.readFileSync(proof_path));
    const pubSig = JSON.parse(fs.readFileSync(pubSig_path));
    const res = await snarkjs.groth16.verify(vKey, pubSig, proof);
    return res; 
}

module.exports = {
    PoF_Gen,
    PoF_Ver,
}