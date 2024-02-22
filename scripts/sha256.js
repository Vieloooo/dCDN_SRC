const wasm_tester = require("../circom_tester/index").wasm;

/// hash a 256 bits number using sha256 
// input number should be a string like "123"

const N = 8; 

function decimalToBinaryN(decimalString) {
    // Convert the decimal string to a BigInt, then to a binary string
    let binaryString = BigInt(decimalString).toString(2);
    
    // Calculate how many zeros need to be added
    const zerosNeeded = N - binaryString.length;
    
    if (zerosNeeded < 0) {
        throw new Error('The number is too large to be represented with ' + N + ' bits');
    }
    // Pad the binary string with zeros on the left
    binaryString = '0'.repeat(zerosNeeded) + binaryString;
  
    return binaryString;
}

async function sha256_zk(preimage = "4", if_recompile = true) {
    // load the sha256 circuit
    const sha256_cir = await wasm_tester("../circuits/hash_sha256.circom", {
        output: "../tmp",
        recompile: if_recompile,
    });
    let preimage_bin = decimalToBinaryN(preimage);
    console.log(preimage_bin);
    // convert the binary string into array of numbers (string)
    let preimage_array = preimage_bin.split("");
    // remain the rightest N bits
    preimage_array = preimage_array.slice(-N);
    console.log(preimage_array);
    const input = {
        in: preimage_array, // the input of the sha256 circuit
    };
    const wtns = await sha256_cir.calculateWitness(input);
    await sha256_cir.checkConstraints(wtns);
    // get the binary from the wtns
    const result = await sha256_cir.getOutput(wtns, ["out[256]"]);
    // extract the 256 bits hash from the result 
    // init a array of 256 bytes
    const hash_array = [];
    for (let i = 0; i < 256; i++) {
        hash_array.push(result["out[" + i + "]"]);
    }
    let hash = hash_array.join("");
    // convert binary string to hex string 
    hash = BigInt("0b" + hash).toString(16);
    return hash; 
}

module.exports = {
    sha256_zk, 
    decimalToBinaryN
};