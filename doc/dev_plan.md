- [x] implement tweaked chunk enc/dec 
- [x] sha256 circom two number and corresponding test (verify using normal sha256 code)
- [ ] test 256 input sha256 circom consistency with crypto lib : **how to encode a 254 bits big int into 256 bits**. 
- [x] update merkle root code 
- [ ] vxor 
    - generation 
    - export c1, c2, c3 and proof 
    - verify 
- [ ] commitment js 
- [ ] smart contract 
- [ ] goto the next step: POC Demo 

POC DEMO 
We assume only three node, P, R, C. 
1. P , R runs a setup phase and "send" VXOR to C. 
2. C verify VXOR. 
3. P generate the leaf hash, then R and C verify this. 
4. For a file m, P divide this file into chunks, encrypt them and generate commitments. 
5. R verify the chunks and commitment chains. 
6. R encrypt the chunks and generate commitments. 
7. C verify the chunks and commitment chains.
8. C decrypt the chunks with one by one verification. 

DEMO branch two: Proof of fraud
1. we intently build a fraud encryption commitment. 
    - correct (m - h -> c)
    - incorrect (m' - h -> c) m' = m 
2. submit the incorrect commitment onchain. 
3. test our solidity contract. 
