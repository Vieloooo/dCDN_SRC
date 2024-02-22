const fs = require("fs");

const sha256ZKLib = require("../scripts/sha256.js");
describe("cipher functions", function () {
    this.timeout(100000);
    /// before test, generate a ciminion key and convert the original file into PTCs
    before(async () => {
        
    });

    it("should hash a number using sha256", async () => {
        const test_num = "7"; 
        let res = await sha256ZKLib.sha256_zk(test_num);
        //console.log(res);
        let test_num_bin = sha256ZKLib.decimalToBinaryN(test_num);
        console.log("the test_num in binary: ", test_num_bin);
        console.log("the sha256 from circom: ", res);
        // current result (one byte) is consistent with the result from website https://string-o-matic.com/sha256, using hex as input. 
        // for example: 
        //    1. "7" -> 6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01dca358758f6d27e6cf45272937977a748fd88391db679ceda7dc7bf1f005ee879
        // "0" 
        // calculate the sha256 of the test_num using crypto lib 
        const crypto = require('crypto');

        let hex = BigInt(test_num).toString(16); 
        let buffer = Buffer.from(hex, 'hex'); 
        const hash = crypto.createHash('sha256').update(buffer).digest('hex');
        console.log("the sha256 from crypto: ", hash.toString('hex'));
    }); 

    /// after test, remove the ciminion key and all the PTCs, CTCs 
    after(() => {
        // temp test, do not remove the ciminion key
        return; 
        
    });
});
