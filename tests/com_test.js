const chai = require("chai");
const ethers = require('ethers');
describe("cipher functions", function () {
    this.timeout(100000);
    /// before test, generate a ciminion key and convert the original file into PTCs
    before(async () => {
        
    });

    it("should sign a message and pass the verification", async () => {
        // load the commitment library
        const comLib = require("../scripts/commitment.js");
        // generate a private key
        const sk_path = "./eth_sk.txt";
        // generate a message
        const h_prev = "12376969016901735748234494228761607566577764237603762757423708437165437862270"; 
        const h_next = "15039505961546732535180945278238637851438870526974876449916932052548239112577";
        const h_k = "12596744399865808248039551017377954713183300830204176186877180762534911133340";
        const index = "0"; 
        const signature = await comLib.COM_Gen(sk_path, h_prev, h_next, h_k, index);
        // load the pk and get the wallet
        const fs = require('fs');
        let private_key = "0x474e011d884cc7728b32ba5946542d4b2cd3105ebbcf60d981e38486e03e4f5e"
        const wallet = new ethers.Wallet(private_key);
        console.log("Public address", wallet.address);
        const expectedSignerAddress = wallet.address;
        // verify the signature
        const isVerified = await comLib.COM_Ver( h_prev, h_next, h_k, index, signature, expectedSignerAddress);
        chai.assert.equal(isVerified, true, "the signature should be verified");
        
    }); 

    /// after test, remove the ciminion key and all the PTCs, CTCs 
    after(() => {
        // delete the eth key file 
        return; 
        
    });
});
