const chai = require("chai");
describe("cipher functions", function () {
    this.timeout(100000);
    /// before test, generate a ciminion key and convert the original file into PTCs
    before(async () => {
        
    });

    it("should generate vxor and reverse to the inputs", async () => {
        const vxorZKLib = require("../scripts/vxor.js");
        let sk = {
            MK_0: "1023",
            MK_1: "1033",
            nonce: "1033"
        };
        let secret = "11111324234";
        const output = await vxorZKLib.VXOR_Output(sk, secret);
        
        // decrypt the result 
        let c1 = output[0];
        let c2 = output[1];
        let c3 = output[2]; 
        
        const output_rev = await vxorZKLib.VXOR_Rev(c1, c2, c3, secret);
        chai.assert.equal(output_rev[0], sk.MK_0, "MK_0 should be the same");
        chai.assert.equal(output_rev[1], sk.MK_1, "MK_1 should be the same");
        chai.assert.equal(output_rev[2], sk.nonce, "nonce should be the same");
        
    }); 

    /// after test, remove the ciminion key and all the PTCs, CTCs 
    after(() => {
        // temp test, do not remove the ciminion key
        return; 
        
    });
});
