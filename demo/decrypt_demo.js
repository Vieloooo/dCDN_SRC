const file_path =  "../data/src.jpg"; 
const pt_folder = "./PT";
const ct2_folder = "./CT2";
const hash_path = "./pt_hash.json"
const root_path = "./root.json"
const decrypt_path = "./PT_rev"
const DELILib = require("../phase_interface/delivery.js");
const fs = require("fs");
const DECLib = require("../phase_interface/decryption.js");
async function run(){
    // we assume C already knows sk of P, R. 
    // load sk 
    const sk_P = JSON.parse(fs.readFileSync("./P/sk.json"));
    const sk_R = JSON.parse(fs.readFileSync("./R/sk.json"));
    // load the address list
    const eth_addr_list = JSON.parse(fs.readFileSync("./addr_list.json"));
    const P_addr = eth_addr_list[0];
    const R_addr = eth_addr_list[1];
    // verify the commitment chain first 
    const N = 7;
    const com1s = []; 
    for (let i = 0; i < N; i++){
        const com1_path = "./P/com/com_"+i+".json";
        const com1_json = fs.readFileSync(com1_path);
        const com1 = JSON.parse(com1_json);
        com1s.push(com1);
    }
    const com2s = [];
    for (let i = 0; i < N; i++){
        const com2_path = "./R/com/com_"+i+".json";
        const com2_json = fs.readFileSync(com2_path);
        const com2 = JSON.parse(com2_json);
        com2s.push(com2);
    }
    // verify 
    for (let i = 0; i < N; i++){
        const com1 = com1s[i];
        const com2 = com2s[i];
        const res = await DELILib.DELIVERY_ver_com_chain([com1, com2], [P_addr, R_addr]);
        if (res == false){
            console.log("commitment chain verification failed");
            return;
        }
    }
    console.log("R believe that commitment chain verification passed");
    // load ct2 
    const ct2s = [];
    for (let i = 0; i < N; i++){
        const ct2_path = "./CT2/ct_"+i+".json";
        const ct2_json = fs.readFileSync(ct2_path);
        const ct2 = JSON.parse(ct2_json);
        ct2s.push(ct2);
    }
    /*
    // verify the ct2 are consist with com2 
    for (let i = 0; i < N; i++){
        const ct2 = ct2s[i];
        const com2 = com2s[i];
        const res = await DELILib.DELIVERY_encrypt_chunk_ver(ct2, com2, R_addr);
        if (res == false){
            console.log("ct2 and com2 verification failed");
            return;
        }
    }
    console.log(" R believe the final encrypted is consist");
    */
    // decrypt the ciphertext chunks
    let pts = []; 
    for (let i = 0; i < N; i++){
        console.log("Decrypt i-th chunk", i);
        const ct2 = ct2s[i];
        const com1 = com1s[i];
        const com2 = com2s[i];
        const res = await DECLib.DECRYPTION_dec_chunk(ct2, [com1, com2], i.toString(), [sk_P, sk_R]);
        if (res.cheater_idx != -1){
            console.log("cheater found at ", res.cheater_idx);
            return;
        }
        const pt_path = "./PT_rev/pt_"+i+".json";
        const pt_json = JSON.stringify(res.ptc);
        fs.writeFileSync(pt_path, pt_json);
        pts.push(res.ptc);
    }
    pts = await Promise.all(pts);
    return; 
    // save the plaintexts in folder pt_rev 
    for (let i = 0; i < N; i++){
        const pt_path = "./PT_rev/pt_"+i+".json";
        const pt_json = JSON.stringify(pts[i]);
        fs.writeFileSync(pt_path, pt_json);
    }

}
run().then(()=> {process.exit(0);}).catch((e)=>{console.log(e); process.exit(1);}); 