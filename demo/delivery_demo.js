const file_path =  "../data/src.jpg"; 
const pt_folder = "./PT"; 
const ct1_folder = "./CT1";
const ct2_folder = "./CT2";
const hash_path = "./pt_hash.json"
const root_path = "./root.json"
const DELILib = require("../phase_interface/delivery.js");
const fs = require("fs");
async function run(){
    
    console.log("P generate the hash of each chunk");
    await DELILib.DELIVERY_prep(file_path, hash_path, pt_folder, root_path);

    console.log("P send hashes to R and C");

    console.log("R and C verify the hashes");
    const res = await DELILib.DELIVERY_prep_ver(hash_path, root_path);
    console.log("\t the verification result is ", res);

    // P encrypt all chunks in pt_folder and generate commitment 

    console.log("----------------------------------");
    
    console.log("P encrypt all plaintext chunks and generate encryption commitment");
    const sk_path_P = "./P/sk.json";
    const com_folder_P = "./P/com";
    const eth_sk_path_P = "./P/eth_sk.txt";
    await DELILib.DELIVERY_encrypt(pt_folder, sk_path_P, ct1_folder, com_folder_P, eth_sk_path_P);
    
    
    console.log("P send the encrypted chunks to R");
    console.log("R verify the encrypted chunks and the encryption commitment");
    // get file numbers in folder 
    const N = 7; 
    // load the commitment lists 
    const coms = [];
    for (let i = 0; i < N; i++){
        const com_path = "./P/com/com_"+i+".json";
        const com_json = fs.readFileSync(com_path);
        const com = JSON.parse(com_json);
        coms.push(com);
    }
    // load the encrypted chunks
    const ct1s = [];
    for (let i = 0; i < N; i++){
        const ct1_path = "./CT1/ct_"+i+".json";
        const ct1_json = fs.readFileSync(ct1_path);
        const ct1 = JSON.parse(ct1_json);
        ct1s.push(ct1);
    }
    // load P's address 
    const eth_addr_list = JSON.parse(fs.readFileSync("./addr_list.json"));
    const P_addr = eth_addr_list[0];
    // verify each ctc and com 
    for (let i = 0; i < N; i++){
        const com = coms[i];
        const ct1 = ct1s[i];
        //console.log(ct1.length, com, P_addr);
        const res = await DELILib.DELIVERY_encrypt_chunk_ver(ct1, com, P_addr);
        if (res == false){
            console.log("R verify the encrypted chunk and the encryption commitment: ", res);
            return;
        }
    }
    
    console.log("R verify the encrypted chunks and the encryption commitment: ", true);
    console.log("--------------------------");
    const sk_path = "./R/sk.json";
    const com_folder = "./R/com";
    const eth_sk_path = "./R/eth_sk.txt";
    await DELILib.DELIVERY_encrypt(ct1_folder, sk_path, ct2_folder, com_folder, eth_sk_path);
    console.log("C get chunks encrypt by R and generate encryption commitment");
}

run().then(()=> {process.exit(0);}).catch((e)=>{console.log(e); process.exit(1);}); 