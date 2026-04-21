#!/usr/bin/env bash

# From ALCF
# https://docs.alcf.anl.gov/aurora/compiling-and-linking/aurora-example-program-makefile

num_gpu=2 # 6
num_tile=2 # 1

# PALS:
RANK=$PALS_LOCAL_RANKID
# MPICH:
# RANK=$PMI_RANK

gpu_id=$((  ( RANK / num_tile ) % num_gpu ))
tile_id=$((   RANK % num_tile   ))

unset EnableWalkerPartition
export ZE_ENABLE_PCI_ID_DEVICE_ORDER=1
export ZE_AFFINITY_MASK=$gpu_id.$tile_id
export ZE_ENABLE_API_TRACING=0

echo "RANK= ${RANK} gpu= ${gpu_id}  tile= ${tile_id} MASK=$ZE_AFFINITY_MASK"

#https://stackoverflow.com/a/28099707/7674852
"$@"
