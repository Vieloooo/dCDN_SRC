# FairRelay 

Evaluation code for FairRelay. 


## On-chain Evaluation 

Main Contract 
- `Judge.sol`: the Judge Contract used in FairRelay 
- `PoF.sol`: the sub-contract used to verify proof of misbehavior on encryption 
- `PCN.sol`: the payment channel contract. 

Evaluation: put `Judge.t.sol` contract in Froudry, and run `forge test`. You can also test the costs using other platform like Remix. 

## Off-chain Evluation

- Pre-setup: 
    - Fill `/circuits/circomlib` folder with standard circom circuits in  [iden3]{https://github.com/iden3/circomlib/tree/master/circuits}. 
    - Download and the power of tau from [Snarkjs]{https://github.com/iden3/snarkjs}, put them in folder `bench/`
    - In folder `bench`, run `node input_gen.js`, which generates circuits' inputs. 
- Zero-knowledge efficiency in proof of misbehavior on encryption: in folder `bench/Pof/test_*/`, run `eva.sh`. 


## Demonstration 
- In folder `demo`, test each phase by running `node *_test.js`.
