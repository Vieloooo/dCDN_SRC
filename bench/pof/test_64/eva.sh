#!/bin/bash

set -e
SCRIPT=$(realpath "$0")         # Full path of this script
SCRIPT_DIR=$(dirname "$SCRIPT") # Directory of this script
TAU_FILE="../../p16.ptau"
# 时间命令
TIME=(/usr/bin/time -f "mem %M\ntime %e\ncpu %P")

# 设置环境变量
export NODE_OPTIONS=--max_old_space_size=327680

# 编译 Circom 文件
function compile() {
    pushd "$SCRIPT_DIR"
    echo circom test_pof.circom --r1cs --sym --wasm
    circom test_pof.circom --r1cs --sym --wasm
    popd
}

function setup() {
    pushd "$SCRIPT_DIR"
    snarkjs groth16 setup test_pof.r1cs ${TAU_FILE} tk0.zkey
    echo entro | snarkjs zkey contribute tk0.zkey tk1.zkey --name='Vielo' -v
    snarkjs zkey export verificationkey tk1.zkey verification_key.json
    prove_key_size=$(ls -lh tk1.zkey | awk '{print $5}')
    verify_key_size=$(ls -lh verification_key.json | awk '{print $5}')
    echo "Prove key size: $prove_key_size"
    echo "Verify key size: $verify_key_size"
    popd
}

# 生成证据
function generateWtns() {
    pushd "$SCRIPT_DIR"
    echo node test_pof_js/generate_witness.js test_pof_js/test_pof.wasm input.json witness.wtns
    "${TIME[@]}" node test_pof_js/generate_witness.js test_pof_js/test_pof.wasm input.json witness.wtns
    popd
}

# 计算平均时间
avg_time() {
    #
    # usage: avg_time n command ...
    #
    n=$1
    shift
    (($# > 0)) || return # 如果没有给出命令，则退出
    echo "$@"
    for ((i = 0; i < n; i++)); do
        "${TIME[@]}" "$@" 2>&1
    done | awk '
        /mem/ { mem = mem + $2; nm++ }
        /time/ { time = time + $2; nt++ }
        /cpu/  { cpu  = cpu  + substr($2,1,length($2)-1); nc++}
        END    {
                 if (nm>0) printf("mem %f\n", mem/nm);
                 if (nt>0) printf("time %f\n", time/nt);
                 if (nc>0) printf("cpu %f\n",  cpu/nc)
               }'
}

# 普通证明
function normalProve() {
    pushd "$SCRIPT_DIR"
    avg_time 3 snarkjs groth16 prove tk1.zkey witness.wtns proof.json public.json
    proof_size=$(ls -lh proof.json | awk '{print $5}')
    echo "Proof size: $proof_size"
    popd
}

# 验证
function verify() {
    pushd "$SCRIPT_DIR"
    avg_time 3 snarkjs groth16 verify verification_key.json public.json proof.json
    popd
}

echo "========== Step1: compile circom  =========="
compile

echo "========== Step2: setup =========="
setup

echo "========== Step3: generate witness  =========="
generateWtns

echo "========== Step4: prove  =========="
normalProve

echo "========== Step5: verify  =========="
verify
