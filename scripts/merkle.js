const web3 = require("web3");


/// build a merkle root from a list of bigint in string 
//  leaf = sha256(input[i] ||  i)
//  duplicate the last leaf if the number of leaves is odd
function MerkleRoot(BN_list) {
    // calcuate the leaves leaf_i = sha256(BN_list[i], i); 
    let leaves = [];
    const crypto = require('crypto');
    for (let i = 0; i < BN_list.length; i++) {
        let hex = BigInt(BN_list[i]).toString(16); 
        let buffer = Buffer.from(hex, 'hex'); 
        // add index to the buffer 
        buffer = Buffer.concat([buffer, Buffer.from(i.toString())]);
        const hash = crypto.createHash('sha256').update(buffer).digest('hex');
        leaves.push(hash);
    }
    let root = leaves;
    while (root.length > 1) {
        // make the number of leaves even
        if (root.length % 2 == 1) {
            root.push(root[root.length - 1]);
        }
        let new_root = [];
        for (let i = 0; i < root.length; i += 2) {
            let buf_l = Buffer.from(root[i] , 'hex');
            // add the second leaf to the buffer
            let buf_r = Buffer.from(root[i + 1], 'hex');
            let buffer = Buffer.concat([buf_l, buf_r]);
            const hash = crypto.createHash('sha256').update(buffer).digest('hex');
            new_root.push(hash);
        }
        root = new_root;
        
    }
    return root[0];
}

/// verify merkle root
function MerkleRootVerify(BN_list, root) {
    return root == MerkleRoot(BN_list);
}


module.exports = {
    MerkleRoot,
    MerkleRootVerify
}