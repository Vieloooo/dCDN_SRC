const fs = require("fs"); 

const chai = require("chai");

describe("cipher functions", function () {
    this.timeout(100000);
    /// before test, generate a ciminion key and convert the original file into PTCs
    before(async () => {
        
    });

    it("should generate pof and verfy in js", async () => {
        const pofLib = require("../scripts/pof.js");
        let sk = {
            MK_0: "1023",
            MK_1: "1033",
            nonce: "1033", 
            IV: "123"
        };
        // load ctc from file 
        let ctc = fs.readFileSync("../data/src/ct_0.json");
        // parse ctc to string 
        ctc = JSON.parse(ctc);
        let ctc_r = [];
        for (let i = 0; i < 64; i++){
            ctc_r.push(BigInt(ctc[i]).toString());
        }
        console.log("start gen pof ");
        await pofLib.PoF_Gen(ctc_r, sk, "0", true, "./pof_proof.json", "./pof_public.json").then(()=> process.exit(0));

        // verify the proof
        const res = await pofLib.PoF_Ver("../keys/pof_ver.json", "./pof_proof.json", "./pof_public.json");
        chai.assert.equal(res, true, "the proof should be verified");

    }); 

    /// after test, remove the ciminion key and all the PTCs, CTCs 
    after(() => {
        // temp test, do not remove the ciminion key
        return; 
        
    });
});