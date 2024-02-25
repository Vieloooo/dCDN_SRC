const fs = require('fs');
const ciminionLib = require('../scripts/ciminion_key.js');
const merkleLib = require('../scripts/merkle.js');
const cipherLIb = require('../scripts/cipher.js');
const chunkLib = require('../scripts/chunk.js');
const comLib = require('../scripts/commitment.js');
/// load a file from file path, divide into chunks, then cal the hashes and cal the root from json hash of each chunk, save the hash list and merkle root in json 
async function DELIVERY_prep(file_path, hash_path, chunk_folder_path){
    // div file into chunks "i.chunk" and pt_i.json 
    chunkLib.inputFileToBigNumberArrays(file_path, chunk_folder_path);
    // read each chunk
    let ptcs = [] 
    // read all pt_i.json in order in chunk folder, and parse the json 
    const paths = fs.readdirSync(chunk_folder_path);
    let ptc_cnt = 0; 
    for (let i = 0; i < paths.length; i++){
        if (paths[i].startsWith("pt_") && paths[i].endsWith(".json")){
            ptc_cnt += 1;
        }
    }
    for (let i = 0; i < ptc_cnt; i++){
        // read in order, from pt_0.json to pt_n.json
        const ptc_path = path.join(chunk_folder_path, "pt_"+i+".json");
        const ptc_json = fs.readFileSync(ptc_path);
        const ptc = JSON.parse(ptc_json);
        ptcs.push(ptc);
    }
    // cal the hash of each chunks 
    const hashes = await cipherLib.HashPTCs(ptcs);
    // cal the merkle root
    const root = merkleLib.MerkleRoot(hashes);
    // save the hashes and root to json
    const hash_json = JSON.stringify(hashes);
    fs.writeFileSync(hash_path, hash_json);
    const root_json = JSON.stringify(root);
    fs.writeFileSync(hash_path, root_json);
}

/// load the hash list and merkle root from json, then verify this 
async function DELIVERY_prep_ver(hash_path, merkle_root_path){
    // load the hashes and root from json 
    const hashes = JSON.parse(fs.readFileSync(hash_path));
    const root = JSON.parse(fs.readFileSync(merkle_root_path));
    // verify the merkle root
    return merkleLib.MerkleRootVerify(hashes, root);
}

/// load the input chunk folder, for each chunk, encrypt it, generate a commitment then save the ciphers to json

async function DELIVERY_encrypt(chunk_folder_path,sk_path, cipher_folder_path, com_folder_path, eth_sk_path){
    const sk = ciminionLib.LoadCIminionKeyJson(sk_path);
    // read each chunk paths in order, add to a list. all chunk end with _i.json 
    const paths = fs.readdirSync(chunk_folder_path);
    const input_chunk_paths = []; 
    for (let i = 0; i < paths.length; i++){
        if (paths[i].endsWith(".json")){
            input_chunk_paths.push(paths[i]);
        }
    }
    // sort the chunk paths 
    input_chunk_paths.sort();
    console.log(input_chunk_paths);
    // for each chunk, encrypt it, generate a commitment then save the ciphers to json
    let com_and_ctc = []; 
    for (let i = 0; i < input_chunk_paths.length; i++){
        const chunk_path = path.join(chunk_folder_path, input_chunk_paths[i]);
        const chunk_json = fs.readFileSync(chunk_path); 
        const chunk = JSON.parse(chunk_json);
        // encrypt the chunk and gen com 
        com_and_ctc.push(DELIVERY_encrypt_chunk(chunk, sk, eth_sk_path, i));
    }
    // wait for all the ciphers to finish
    com_and_ctc = await Promise.all(com_and_ctc);
    // seperate ctcs and coms
    const ctcs = [];
    const sigs = [];
    for (let i = 0; i < com_and_ctc.length; i++){
        ctcs.push(com_and_ctc[i].ctc);
        sigs.push(com_and_ctc[i].sig);
    }
    // save ctcs in jsonm name "ct_i.json"
    for (let i = 0; i < ctcs.length; i++){
        const ctc_path = path.join(cipher_folder_path, "ct_"+i+".json");
        fs.writeFileSync(ctc_path, JSON.stringify(ctcs[i]));
    }
    // compose commitment by sig
    for (let i = 0; i < sigs.length; i++){
        const com_path = path.join(com_folder_path, "com_"+i+".json");
        fs.writeFileSync(com_path, JSON.stringify(sigs[i]));
    }

}

/// load one chunk, sk, pubkey, return the encryption result and a commitment. index is a number 
async function DELIVERY_encrypt_chunk(chunk, sk, eth_sk_path, index){
    /// encrypt the chunk
    const ctc = await cipherLib.PTCtoCTC_tweak(chunk, sk, index.toString(), false);
    /// cal the hash of chunk and ctc 
    const hash_in = await cipherLib.HashCTC(chunk);
    const hash_out = await cipherLib.HashCTC(ctc);
    /// generate hash of ciminion sk 
    const hash_sk = await ciminionLib.HashKey(sk);
    /// generate commitment 
    const sig = await comLib.COM_Gen(eth_sk_path, hash_in, hash_out, hash_sk, index.toString());
    const com = {
        h_in: h_in, 
        h_out: h_out,
        h_sk: h_sk,
        index: index.toString(),
        sig: sig,

    }
    return {ctc, com }; 
}

/// verify a ciphertext chunk with its commitment 
async function DELIVERY_encrypt_chunk_ver(ctc, com, eth_address){
    // verify the hash of ctc, check if ctc's hash = com.h_out 
    const hash_out = await cipherLib.HashCTC(ctc);
    if (hash_out != com.h_out){
        return false;
    }
    // check if the commitment is signed by the right person
    const res = await comLib.COM_Ver(com.h_in, com.h_out, com.h_sk, com.index, com.sig, eth_address);
    return res; 

}
/// verify the commitment chain. input is a list of commitment and a list of address 
async function DELIVERY_ver_com_chain(coms, eth_addresses){
    // verify the commitment chain 
    for (let i = 0; i < coms.length ; i++){
        // check the sig of each com 
        const res = await comLib.COM_Ver(coms[i].h_in, coms[i].h_out, coms[i].h_sk, coms[i].index, coms[i].sig, eth_addresses[i]);
        if (!res){
            return false;
        }
    }
    // check the coms[i].h_out = coms[i+1].h_in
    for (let i = 0; i < coms.length - 1; i++){
        if (coms[i].h_out != coms[i+1].h_in){
            return false;
        }
    }
    return true; 
}