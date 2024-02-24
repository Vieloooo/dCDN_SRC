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
        comLib.generatePrivateKey(sk_path);
        // generate a message
        const h_prev = "23423523462323"; 
        const h_next = "23423523342323";
        const h_k = "23423523462323";
        const index = "5"; 
        const signature = await comLib.COM_Gen(sk_path, h_prev, h_next, h_k, index);
        console.log("Msg: ", "{" + h_prev + ", " + h_next + ", " + h_k + ", " + index + "}");
        console.log("Signature: ", signature);
        // load the pk and get the wallet
        const fs = require('fs');
        let private_key = fs.readFileSync(sk_path);
        private_key = private_key.toString(); 
        const wallet = new ethers.Wallet(private_key);
        const expectedSignerAddress = wallet.address;
        // verify the signature
        const isVerified = await comLib.COM_Ver("{" + h_prev + ", " + h_next + ", " + h_k + ", " + index + "}", signature, expectedSignerAddress);
        chai.assert.equal(isVerified, true, "the signature should be verified");
        
    }); 

    /// after test, remove the ciminion key and all the PTCs, CTCs 
    after(() => {
        // delete the eth key file 
        const fs = require('fs');
        fs.unlinkSync("./eth_sk.txt");
        return; 
        
    });
});
