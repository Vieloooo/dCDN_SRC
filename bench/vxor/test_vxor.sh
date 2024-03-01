#!/bin/bash 

set -e 
SCRIPT=$(realpath "$0") # Full path of this script
SCRIPT_DIR=$(dirname "$SCRIPT") # Directory of this script
CIRCUIT_PATH=${SCRIPT_DIR}"/../../circuits/vxor.circom"
ZKEY_PATH="../../keys/16_vxor_1.zkey"
# 时间命令
TIME=(/usr/bin/time -f "mem %M\ntime %e\ncpu %P")


# 设置环境变量
export NODE_OPTIONS=--max_old_space_size=327680


# 编译 Circom 文件
function compile() {
  pushd "$SCRIPT_DIR"
  echo circom "$CIRCUIT_PATH" --r1cs --sym --wasm -o "$SCRIPT_DIR"
  circom "$CIRCUIT_PATH" --r1cs --sym --wasm -o "$SCRIPT_DIR"
  popd
}


# 生成证据
function generateWtns() {
  pushd "$SCRIPT_DIR"
  echo node vxor_js/generate_witness.js vxor_js/vxor.wasm input.json witness.wtns
  "${TIME[@]}" node vxor_js/generate_witness.js vxor_js/vxor.wasm input.json witness.wtns
  popd
}

# 计算平均时间
avg_time() {
    #
    # usage: avg_time n command ...
    #
    n=$1; shift
    (($# > 0)) || return                   # 如果没有给出命令，则退出
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
  avg_time 3 snarkjs groth16 prove $ZKEY_PATH witness.wtns proof.json public.json
  proof_size=$(ls -lh proof.json | awk '{print $5}')
  echo "Proof size: $proof_size"
  popd
}


# 验证
function verify() {
  pushd "$SCRIPT_DIR"
  avg_time 3 snarkjs groth16 verify "../../keys/vxor_ver.json" public.json proof.json
  popd
}

echo "========== Step1: compile circom  =========="
compile

echo "========== Step2: setup =========="
# setup

echo "========== Step3: generate witness  =========="
generateWtns

echo "========== Step4: prove  =========="
normalProve

echo "========== Step5: verify  =========="
verify