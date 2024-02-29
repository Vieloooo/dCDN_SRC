const ethers = require('ethers');
const { Web3, eth } = require('web3');
// Specify the provider as needed, for example, an Ethereum node URL
const web3 = new Web3('http://localhost:8545');
const ethUtil = require('ethereumjs-util');

/// generate a private key and write it to a file
function generatePrivateKey(pk_path) {
    const wallet = ethers.Wallet.createRandom();
    console.log("Private Key:", wallet.privateKey);
    console.log("Address:", wallet.address);
    // write the private key to a file 
    const fs = require('fs');
    fs.writeFileSync(pk_path, wallet.privateKey);
    
    //return wallet.privateKey;
    return wallet.address;
}

/// sign a message in string format, and return the calldata for solidity verification 
async function signMessage_sol(message, sk_path="eth_sk.txt") {
    // 获取将签名的消息的哈希
    const messageHash = ethers.utils.id(message);
    // load pk and get wallet 
    const fs = require('fs');
    let private_key = fs.readFileSync(sk_path);
    private_key = private_key.toString();
    const account = web3.eth.accounts.privateKeyToAccount(private_key);
    let msg_array = Buffer.alloc(32, messageHash.slice(2), 'hex');
    let pk_array = Buffer.alloc(32, account.privateKey.slice(2), 'hex');
    let sig = ethUtil.ecsign(msg_array, pk_array);
    // split signature
    const r = '0x' + sig.r.toString('hex');
    const s = '0x' + sig.s.toString('hex');
    const v = sig.v;
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
    // get msghash buffer
    let msg_array = Buffer.alloc(32, messageHash.slice(2), 'hex');
    // recover 
    const recv_pub = ethUtil.ecrecover(msg_array, signature.v, Buffer.from(signature.r.slice(2), 'hex'), Buffer.from(signature.s.slice(2), 'hex'));
    // get the addr 
    const addrBuf = ethUtil.pubToAddress(recv_pub);
    const recv_pub_hex = '0x' + addrBuf.toString('hex');
    console.log("rev signer: ", recv_pub_hex, expectedSignerAddress);
    // 比较恢复出的地址和预期的签名者地址
    const isVerified = recv_pub_hex.toLowerCase() === expectedSignerAddress.toLowerCase();
    return isVerified;
}


module.exports = {
    generatePrivateKey,
    COM_Gen,
    COM_Ver,

};
