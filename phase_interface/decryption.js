const cipherLib = require('../scripts/ciphers.js');
/// now the customer has a ciphertext chunk, and address list, and the commitment chain. the order of the address if from the first node(provider) to the last node (the last relay)
/// the customer will decrypt the ciphertext chunk layer by layer, in each layer the customer will verify the result. 

async function DECRYPTION_dec_chunk_layer(ctc, sk, com, index){
    // decrypt the chunk 
    const ptc = await cipherLib.CTCtoPTC_tweak(ctc, sk, index.toString(), false);
    // check if the ptc's hash is consist with com.h_in 
    const hash_in = await cipherLib.HashCTC(ptc);
    if (hash_in != com.h_in){
        return {res: false, ptc: ptc};
    }
    return {res: true, ptc: ptc};
}

async function DECRYPTION_dec_chunk(ctc, com_chain, index,  sk_list){
    // check the consistency of the com_chain and the address_list, they should have the same length 
    if (com_chain.length != sk_list.length){
        return {cheater_idx: -1, ptc: null};
    } 
    // decrypt the chunk layer by layer
    let ptc = ctc;
    for (let i = com_chain.length -1; i >=0; i--){
        const res = await DECRYPTION_dec_chunk_layer(ptc, sk_list[i], com_chain[i], index);
        if (!res.res){
            return {cheater_idx: i, ptc: res.ptc}; 
        }
        ptc = res.ptc;
    }
    return {cheater_idx: -1, ptc: ptc};
}

module.exports = {
    DECRYPTION_dec_chunk, 
    DECRYPTION_dec_chunk_layer, 
}