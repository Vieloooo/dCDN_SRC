const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString(
    "21888242871839275222246405745257275088548364400416034343698204186575808495617"
);

const Fr = new F1Field(exports.p);
const wasm_tester = require("../circom_tester/index").wasm;
const snarkjs = require("snarkjs");


/// Generate vxor result and corresponding hashes without generate the proof, only generate c1, c2, c3 and h_k, h_s 
// secret is a BN number 
async function VXOR_Output(sk, secret , if_recompile = true ){
    // load the vxor circuit
    const vxor_cir = await wasm_tester("../circuits/vxor.circom", {
        output: "../tmp",
        recompile: if_recompile,
    });
    // build the input for the circuit 
    const input = {
        MK_0: sk.MK_0,
        MK_1: sk.MK_1,
        nonce: sk.nonce,
        secret: secret
    };
    // generate the output using the circuits 
    const wtns = await vxor_cir.calculateWitness(input);
    // get the output 
    const outputs = await vxor_cir.getOutput(wtns, ["c1", "c2", "c3", "h_k", "h_s[256]"])
    // filter the c1 (c1 = MK_0 xor secret) from outputs 
    const c1 = outputs["c1"];
    // filter the c2 (c2 = MK_1 xor poseidon(secret, 1) ) from outputs
    const c2 = outputs["c2"];
    // filter the c3 (c3 = MK_1 xor poseidon(secret, 2) ) from outputs
    const c3 = outputs["c3"];
    // filter the h_k (h_k = poseidon(MK_0, MK_1, nonce) ) from outputs
    const h_k = outputs["h_k"];
    // h_s is a sha256 result in bits, so it is a array of 256 numbers
    let h_s = ""; 
    for (let i = 0; i < 256; i++) {
        h_s += outputs["h_s[" + i + "]"];
    }
    // convert h_s from a binary string to a hex string 
    h_s = BigInt("0b" + h_s).toString(16);
    //console.log(c1, c2, c3, h_k, h_s);
    return [c1, c2, c3, h_k, h_s];
}
/// reverse VXOR process 
// inputs: c1, c2, c3 and secret, generate MK_0, MK_1 and nonce 
async function VXOR_Rev(c1, c2, c3, secret, if_recompile){
    // load the vxor circuit
    const vxor_cir = await wasm_tester("../circuits/vxor_rev.circom", {
        output: "../tmp",
        recompile: if_recompile,
    });
    // build the input for the circuit 
    const input = {
        c1: c1, 
        c2: c2, 
        c3: c3, 
        secret: secret, 
    };
    // generate the output using the circuits 
    const wtns = await vxor_cir.calculateWitness(input);
    // get the output 
    const outputs = await vxor_cir.getOutput(wtns, ["MK_0", "MK_1", "nonce"]); 
    //console.log(outputs["MK_0"], outputs["MK_1"], outputs["nonce"]);
    return [outputs["MK_0"], outputs["MK_1"], outputs["nonce"]];
}

/// Generate VXOR and corresbonding proofs 
// add then(()=> process.exit(0)) for this async function 
async function VXOR_Gen(sk, secret , if_recompile = true, proof_path="./proof.json", pubSig_path = "./public.json"){
    // load the vxor circuit
    const vxor_cir = await wasm_tester("../circuits/vxor.circom", {
        output: "../tmp",
        recompile: if_recompile,
    });
    const cir_wasm_path = "../tmp/vxor_js/vxor.wasm";
    const final_zkey_path = "../keys/16_vxor_1.zkey";
    // build the input for the circuit 
    const input = {
        MK_0: sk.MK_0,
        MK_1: sk.MK_1,
        nonce: sk.nonce,
        secret: secret
    };
    // generate proofs 
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(input, cir_wasm_path, final_zkey_path);
    // export the proof to json 
    const proof_json = JSON.stringify(proof, null, 1);
    const pubSig_json = JSON.stringify(publicSignals, null, 1);
    const fs = require('fs');
    fs.writeFileSync(proof_path, proof_json);
    fs.writeFileSync(pubSig_path, pubSig_json);
    return true; 
}
// bool function to verify the proof
async function VXOR_Ver(verify_key_path= "../keys/vxor_ver.json", proof_path = "./proof.json", pubSig_path="public.json"){
    const fs = require('fs');
    const vKey = JSON.parse(fs.readFileSync(verify_key_path));
    const proof = JSON.parse(fs.readFileSync(proof_path));
    const pubSig = JSON.parse(fs.readFileSync(pubSig_path));
    const res = await snarkjs.groth16.verify(vKey, pubSig, proof);
    return res; 

}

module.exports = {
    VXOR_Output,
    VXOR_Rev,
    VXOR_Gen,
    VXOR_Ver
}

