const comLib = require("../scripts/commitment.js");

const addr_P = comLib.generatePrivateKey("./P/eth_sk.txt");

const addr_R = comLib.generatePrivateKey("./R/eth_sk.txt");
const addr_C = comLib.generatePrivateKey("./C/eth_sk.txt");

// write the address in a json list 
const fs = require('fs');
const addr_list = JSON.stringify([addr_P, addr_R, addr_C]);
fs.writeFileSync("./addr_list.json", addr_list);
