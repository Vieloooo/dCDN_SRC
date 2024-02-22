/// Test the merkle tree functions
const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);
const chai = require("chai");
const merkle = require("../scripts/merkle.js");
const rand = require('../scripts/ciminion_key.js').randomScalar;

describe("merkle tree test", function () {
    ///before test, generate a list of hashes (bigint in string format) in Fr 
    const hashList = [];
    let root = "";
    let root1   = "";
    before(async () => {
        for (let i = 0; i < 64; i++) {
            hashList.push(rand(Fr).toString());
            
        }
        root1 = merkle.MerkleRoot(hashList);
    });
    /// Test 1: test the merkle root function, run twice to if if the result is the same
    it("should return the merkle root", async () => {
        const root2 = merkle.MerkleRoot(hashList);
        chai.assert.equal(root1, root2);
        console.log(root1);
        root = root1; 
    });

}); 
