const ethers = require('ethers');

/// generate a private key and write it to a file
function generatePrivateKey(pk_path) {
    const wallet = ethers.Wallet.createRandom();
    console.log("Private Key:", wallet.privateKey);
    console.log("Address:", wallet.address);
    // write the private key to a file 
    const fs = require('fs');
    fs.writeFileSync(pk_path, wallet.privateKey);
    
    //return wallet.privateKey;
}
/// sign a message in string format
async function signMessage(message, sk_path="eth_sk.txt") {
    // 获取将签名的消息的哈希
    const messageHash = ethers.utils.id(message);
    // load pk and get wallet 
    const fs = require('fs');
    let private_key = fs.readFileSync(sk_path);
    private_key = private_key.toString();
    console.log(private_key, typeof(private_key));
    const wallet = new ethers.Wallet(private_key);
    // 签名消息哈希
    const signature = await wallet.signMessage(ethers.utils.arrayify(messageHash));
    console.log("Message:", message);
    console.log("Signature:", signature);
    return signature;
}

/// sign a message in string format, and return the calldata for solidity verification 
async function signMessage_sol(message, sk_path="eth_sk.txt") {
    // 获取将签名的消息的哈希
    const messageHash = ethers.utils.id(message);
    // load pk and get wallet 
    const fs = require('fs');
    let private_key = fs.readFileSync(sk_path);
    private_key = private_key.toString();
    console.log(private_key, typeof(private_key));
    const wallet = new ethers.Wallet(private_key);
    // 签名消息哈希
    const signature = await wallet.signMessage(ethers.utils.arrayify(messageHash));
    console.log("Message:", message);
    console.log("Signature:", signature);
    // split signature
    const r = signature.slice(0, 66);
    const s = "0x" + signature.slice(66, 130);
    const v = parseInt(signature.slice(130, 132), 16);
    return {r, s, v};
}


/// generate encryption commitment. 
// pk_path: the path to the private key file
// message = {h_pre, h_nxt, h_k, index}, all hash are a BN254 number in string format, and index is a int32 number 
async function COM_Gen(sk_path="./eth_sk.txt", h_pre, h_nxt, h_k, index){
    // compose the message in string format, concat all info to {h_pre, h_nxt, h_k, index}. for example "{123456, 123, 124, 4}"
    // all hash are in decimal string format. 
    const message = "{" + h_pre + ", " + h_nxt + ", " + h_k + ", " + index + "}";
    // sign message 
    const signature = await signMessage_sol(message, sk_path);
    return signature; 
}

async function COM_Ver( h_pre, h_nxt, h_k, index, signature, expectedSignerAddress) {
    const message = "{" + h_pre + ", " + h_nxt + ", " + h_k + ", " + index + "}";
    // 假设 message 是一个字符串，signature 是由签名者生成的签名
    // 计算消息的以太坊特定签名哈希 (EIP-191)
    const messageHash = ethers.utils.id(message);
    const messageHashBytes = ethers.utils.arrayify(messageHash);
    // combine r, s, v to a full signature 
    signature = signature.r + signature.s.slice(2) + signature.v.toString(16);
    console.log("sig after", signature);
    // 通过签名恢复出签名者的地址
    const recoveredSignerAddress = ethers.utils.verifyMessage(messageHashBytes, signature);
    
    // 比较恢复出的地址和预期的签名者地址
    const isVerified = recoveredSignerAddress.toLowerCase() === expectedSignerAddress.toLowerCase();
    return isVerified;
}


module.exports = {
    generatePrivateKey,
    COM_Gen,
    COM_Ver,

};
