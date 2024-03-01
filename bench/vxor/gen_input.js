/* 
signal input MK_0; 
    signal input MK_1; 
    signal input nonce; 
    signal input secret; 
*/ 

let sk = {
    MK_0: "1023",
    MK_1: "1033",
    nonce: "1033", 
    secret: "11111324234"
};

// write the input to a json file ./input.json 
const fs = require("fs");
fs.writeFileSync("./input.json", JSON.stringify(sk));
