

function GenInputN(n, dir_path){
    let input = {
        MK_0: "523423",
        MK_1: "634634636543",
        nonce: "23423523",
        IV: "123", 
        CTC_r: [],
        r: "0", 
    }
    
    // fill the inputs, generate 64 string number in CTC_r 
    for (let i = 0; i < n; i++){
        input.CTC_r.push(i.toString());
    }
    // write to file json 
    const fs = require("fs");
    fs.writeFileSync(dir_path + "/input.json", JSON.stringify(input, null, 1));
}

GenInputN(64, "./test_64");
GenInputN(128, "./test_128");
GenInputN(256, "./test_256");
GenInputN(512, "./test_512");