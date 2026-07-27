#!/bin/bash
set -eu

# AFFINITY SH
# Source this to get CUDA or ZE settings for given GPUs and TILES
# Assumes RANK is set
# Sets human-readable AFFINITY_LABEL for logging or whatever

# See set_affinity_gpu_aurora.sh from:
# https://docs.alcf.anl.gov/aurora/compiling-and-linking/aurora-example-program-makefile

num_gpu=6 # 6
num_tile=2 # 1

HOSTDOMAIN=$( hostname -d )

# sleep $[ RANK * 10 ]
# echo "affinity start $RANK ..."

if [[ $HOSTDOMAIN == *aurora* ]]
then

  gpu_id=$((  ( RANK / num_tile ) % num_gpu ))
  tile_id=$((   RANK % num_tile   ))

  unset EnableWalkerPartition
  export ZE_ENABLE_PCI_ID_DEVICE_ORDER=1
  export ZE_AFFINITY_MASK=$gpu_id.$tile_id
  export ZE_ENABLE_API_TRACING=0

  AFFINITY_LABEL="ZE_AFFINITY_MASK=$ZE_AFFINITY_MASK"

  # printf "AFFINITY %3i %s\n" $RANK $AFFINITY_LABEL

elif [[ $HOSTDOMAIN == *perlm* ]]
then

  export CUDA_VISIBLE_DEVICES=$(( RANK % num_gpu ))
  AFFINITY_LABEL="CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"

else
  :
#   Actually we probably want to allow miscellaneous systems to just run,
#   for example, local execution.

#   echo "affinity.sh: unknown host: $HOSTDOMAIN"
#   AFFINITY_LABEL="UNKNOWN"
#   return 1

fi

# echo "affinity hand-off:"
# set -x
${*}
