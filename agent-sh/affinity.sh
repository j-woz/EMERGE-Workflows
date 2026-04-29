
# Source this to get CUDA or ZE settings for given GPUs and TILES
# Assumes RANK is set
# Sets human-readable AFFINITY_LABEL for logging or whatever

num_gpu=4 # 6
num_tile=1 # 1

HOSTDOMAIN=$( hostname -d )

if [[ $HOSTDOMAIN == *aurora* ]]
then

  gpu_id=$((  ( RANK / num_tile ) % num_gpu ))
  tile_id=$((   RANK % num_tile   ))

  unset EnableWalkerPartition
  export ZE_ENABLE_PCI_ID_DEVICE_ORDER=1
  export ZE_AFFINITY_MASK=$gpu_id.$tile_id
  export ZE_ENABLE_API_TRACING=0

  AFFINITY_LABEL="ZE_AFFINITY_MASK=$ZE_AFFINITY_MASK"

elif [[ $HOSTDOMAIN == *perlm* ]]
then

  export CUDA_VISIBLE_DEVICES=$(( RANK % num_gpu ))
  AFFINITY_LABEL="CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"

else
  echo "affinity.sh: unknown host: $HOSTDOMAIN"
  AFFINITY_LABEL="UNKNOWN"
  return 1
fi
