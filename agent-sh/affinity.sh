
# Source this to get ZE settings for given GPUs and TILES
# Assumes RANK is set

num_gpu=6 # 6
num_tile=2 # 1

gpu_id=$((  ( RANK / num_tile ) % num_gpu ))
tile_id=$((   RANK % num_tile   ))

unset EnableWalkerPartition
export ZE_ENABLE_PCI_ID_DEVICE_ORDER=1
export ZE_AFFINITY_MASK=$gpu_id.$tile_id
export ZE_ENABLE_API_TRACING=0
