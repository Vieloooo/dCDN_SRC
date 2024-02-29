const { Web3 } = require('web3');
// Specify the provider as needed, for example, an Ethereum node URL
const web3 = new Web3('http://localhost:8545');
const ethUtil = require('ethereumjs-util');
const { slug } = require('mocha/lib/utils');

async function run(){
// Test commitment signature
const tweak_msg ="{12376969016901735748234494228761607566577764237603762757423708437165437862272, 15039505961546732535180945278238637851438870526974876449916932052548239112577, 12596744399865808248039551017377954713183300830204176186877180762534911133340, 0}";
const com_msg_hash = "0xab8cf2037c92e75223d74c8700953ffe6c3d08e13bbe37320b960e3574fd81c6"; 
console.log("Com Msg Hash:", com_msg_hash, typeof(com_msg_hash));
const signer_sk = "0x474e011d884cc7728b32ba5946542d4b2cd3105ebbcf60d981e38486e03e4f5e";

// Calculating account address from private key
const account = web3.eth.accounts.privateKeyToAccount(signer_sk);
console.log("Sender addr:", account.address);

// Signing the message hash
// convert msg hash to buffer
let tt   = Buffer.alloc(32,com_msg_hash.slice(2), 'hex')
console.log(tt, typeof(tt), tt[0]);
let sig =  ethUtil.ecsign(tt, Buffer.alloc(32, signer_sk.slice(2), 'hex'));

let signature = sig; 

// 签名是个对象{ r, s, v }，你可能需将其转换为hex字符串
const signatureHex = ethUtil.toRpcSig(signature.v, signature.r, signature.s);

console.log("Signature:", signatureHex);

// print r, s, in hex and v as a uint8 
console.log("r:", signature.r.toString('hex'));
console.log("s:", signature.s.toString('hex'));
console.log("v:", signature.v);
}

run().then(() => {
    console.log("Done");
    process.exit(0);
}); 