const { debug } = require("request");

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString(
    "21888242871839275222246405745257275088548364400416034343698204186575808495617"
);

const Fr = new F1Field(exports.p);
const wasm_tester = require("../circom_tester/index").wasm;
//const c_tester = require("../circom_tester/index").c;

/// encrypt a plaintext array (64 number in an array) into a ciphertext array in string
// ptc should be an array of numbers in BN254
// sk should be an object with 4 keys: MK_0, MK_1, IV, nonce
async function PTCtoCTC(ptc, sk, if_recompile = true) {
    // load the encrypted circuit
    const chunk_encoder = await wasm_tester("../circuits/enc64.circom", {
        output: "../tmp",
        recompile: if_recompile,
    });
    const input = {
        PT: ptc,
        MK_0: sk.MK_0,
        MK_1: sk.MK_1,
        IV: sk.IV,
        nonce: sk.nonce,
    };
    const wtns = await chunk_encoder.calculateWitness(input);
    await chunk_encoder.checkConstraints(wtns);
    // get the ciphertext from the wtns
    const ctc = await chunk_encoder.getOutput(wtns, ["CT[64]"]);
    // the ctc is an map from CT[i] to string, convert to array of strings with the order of CT[0], CT[1], ..., CT[63]
    const ctc_array = [];
    for (let i = 0; i < 64; i++) {
        ctc_array.push(ctc["CT[" + i + "]"]);
    }
    // convert the array of strings to array of numbers using ffjavascript in the filed Fr
    return ctc_array;
}

/// encrypt a plaintext array (64 number in an array) into a ciphertext array in string with tweak nonce (index is string too)
// ptc should be an array of numbers in BN254
// sk should be an object with 4 keys: MK_0, MK_1, IV, nonce
async function PTCtoCTC_tweak(ptc, sk, index, if_recompile = true) {
    // load the encrypted circuit
    const chunk_encoder = await wasm_tester("../circuits/enc_tweak64.circom", {
        output: "../tmp",
        recompile: if_recompile,
    });
    const input = {
        PT: ptc,
        MK_0: sk.MK_0,
        MK_1: sk.MK_1,
        IV: sk.IV,
        nonce: sk.nonce,
        index: index,
    };
    const wtns = await chunk_encoder.calculateWitness(input);
    await chunk_encoder.checkConstraints(wtns);
    // get the ciphertext from the wtns
    const ctc = await chunk_encoder.getOutput(wtns, ["CT[64]"]);
    // the ctc is an map from CT[i] to string, convert to array of strings with the order of CT[0], CT[1], ..., CT[63]
    const ctc_array = [];
    for (let i = 0; i < 64; i++) {
        ctc_array.push(ctc["CT[" + i + "]"]);
    }
    // convert the array of strings to array of numbers using ffjavascript in the filed Fr
    return ctc_array;
}

/// decrypt a ciphertext array into a plaintext array in string
// ctc should be an array of numbers in BN254
// sk should be an object with 4 keys: MK_0, MK_1, IV, nonce, all in string format
async function CTCtoPTC(ctc, sk, if_recompile = true) {
    // load the decrypted circuit
    const chunk_decoder = await wasm_tester("../circuits/dec64.circom", {
        output: "../tmp",
        recompile: if_recompile,
    });
    const wtns = await chunk_decoder.calculateWitness({
        CT: ctc,
        MK_0: sk.MK_0,
        MK_1: sk.MK_1,
        IV: sk.IV,
        nonce: sk.nonce,
    });
    await chunk_decoder.checkConstraints(wtns);
    // get the plaintext from the wtns
    const ptc = await chunk_decoder.getOutput(wtns, ["PT[64]"]);
    // the ptc is an map from PT[i] to string, convert to array of strings with the order of PT[0], PT[1], ..., PT[63]
    const ptc_array = [];
    for (let i = 0; i < 64; i++) {
        ptc_array.push(ptc["PT[" + i + "]"]);
    }
    return ptc_array;
}

/// decrypt a ciphertext array into a plaintext array in string
// ctc should be an array of numbers in BN254
// sk should be an object with 4 keys: MK_0, MK_1, IV, nonce, all in string format
async function CTCtoPTC_tweak(ctc, sk,index, if_recompile = true) {
    // load the decrypted circuit
    const chunk_decoder = await wasm_tester("../circuits/dec_tweak64.circom", {
        output: "../tmp",
        recompile: if_recompile,
    });
    const wtns = await chunk_decoder.calculateWitness({
        CT: ctc,
        MK_0: sk.MK_0,
        MK_1: sk.MK_1,
        IV: sk.IV,
        nonce: sk.nonce,
        index: index,
    });
    await chunk_decoder.checkConstraints(wtns);
    // get the plaintext from the wtns
    const ptc = await chunk_decoder.getOutput(wtns, ["PT[64]"]);
    // the ptc is an map from PT[i] to string, convert to array of strings with the order of PT[0], PT[1], ..., PT[63]
    const ptc_array = [];
    for (let i = 0; i < 64; i++) {
        ptc_array.push(ptc["PT[" + i + "]"]);
    }
    return ptc_array;
}

/// caculate the hash of a ciphertext array
async function HashCTC(ctc, if_recompile = true) {
    // load the hash circuit
    const chunk_hash = await wasm_tester("../circuits/hash64.circom", {
        output: "../tmp",
        recompile: if_recompile,
    });
    
    const wtns = await chunk_hash.calculateWitness({ in: ctc });
    await chunk_hash.checkConstraints(wtns);
    // get the hash from the wtns
    const hash = chunk_hash.getOutput(wtns, ["out"]);
    // convert the hash from string to number using ffjavascript in the filed Fr
    return hash;
}

/// encrypts multi PTCs into multi CTCs, utilizing no recompile and multithread to save time
async function PTCstoCTCs_tweak(ptcs, sk) {
    // check ptcs length 
    if (ptcs.length == 0) {
        return [];
    }
    // get the number of ptcs
    const n = ptcs.length;
    let ctcs = [];
    // for the first ptc, recompile the circuit, and wait for the compilation to finish
    ctcs.push(await PTCtoCTC_tweak(ptcs[0], sk, "0",  true));
    // for the rest ptcs, no recompile, and run in parallel, watch out the order of the ctcs array
    for (let i = 1; i < n; i++) {
        // does the order of result match the order of input?
        console.log("start enc chunk: ", i);
        // convert the index to string
        let index = i.toString();
        ctcs.push(PTCtoCTC_tweak(ptcs[i], sk, index, false));
    }
    // wait for all the ctcs to finish
    ctcs = await Promise.all(ctcs);
    console.log("finish enc a chunk list");
    return ctcs;
}

/// decrypts multi CTC into multi PTC, utilizing no recompile and multithreadk to save time
async function CTCstoPTCs_tweak(ctcs, sk) {
    // get the number of ctcs
    const n = ctcs.length;
    let ptcs = [];
    // todo: tweak k
    // for the first ctc, recompile the circuit, and wait for the compilation to finish
    ptcs.push(await CTCtoPTC_tweak(ctcs[0], sk, "0", true));
    // for the rest ctcs, no recompile, and run in parallel, watch out the order of the ptcs array
    for (let i = 1; i < n; i++) {
        // does the order of result match the order of input?
        ptcs.push(CTCtoPTC_tweak(ctcs[i], sk, i.toString(), false));
    }
    // wait for all the ptcs to finish
    ptcs = await Promise.all(ptcs);
    return ptcs; 
}

/// hash all ctcs 
async function HashCTCs(ctcs) {
    // get the number of ctcs
    const n = ctcs.length;
    let hashes = [];
    // for the first ctc, recompile the circuit, and wait for the compilation to finish
    hashes.push(await HashCTC(ctcs[0], true));
    // for the rest ctcs, no recompile, and run in parallel, watch out the order of the hashes array
    for (let i = 1; i < n; i++) {
        // does the order of result match the order of input?
        hashes.push(HashCTC(ctcs[i], false));
    }
    // wait for all the hashes to finish
    hashes = await Promise.all(hashes);
    return hashes; 
}

/// hash the key using poseidon h = poseidon (MK_0, MK_1, nonce)
async function HashKey(sk, if_recompile = true) {
    // load the hash circuit
    const key_hash = await wasm_tester("../circuits/hash_key.circom", {
        output: "../tmp",
        recompile: if_recompile,
    });
    const input = {
        MK_0: sk.MK_0,
        MK_1: sk.MK_1,
        nonce: sk.nonce, 
    }
    const wtns = await key_hash.calculateWitness(input);
    await key_hash.checkConstraints(wtns);
    // get the hash from the wtns
    const output = await key_hash.getOutput(wtns, ["h_sk"]);
    // convert the hash from string to number using ffjavascript in the filed Fr
    return output['h_sk']; 
}
module.exports = {
    PTCtoCTC,
    CTCtoPTC,
    HashCTC,
    PTCstoCTCs_tweak,
    CTCstoPTCs_tweak,
    HashCTCs,
    PTCtoCTC_tweak,
    CTCtoPTC_tweak,
    HashKey,
};

