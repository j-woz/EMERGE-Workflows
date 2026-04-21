#!/bin/zsh
set -eu

# source ~/mcs/ZTools/bash_functions

/usr/bin/which mpiexec agent
EXAEPI=/lus/flare/projects/EpiCalib/user/wozniak/proj/ExaEpi

# unset PALS_PMI
d PALS_PMI

# tm mpiexec ${*} ./agent $EXAEPI/examples/inputs.bay agent.fast=1

unset-all FI_ PBS_

# export MPIR_CVAR_NO_LOCAL=1​ #
export FI_PROVIDER=cxi
# export MPIR_CVAR_CH4_XPMEM_ENABLE=0
# export MPIR_CVAR_CH4_CMA_ENABLE=0
# export MPIR_CVAR_CH4_IPC_GPU_P2P_THRESHOLD=10000000000
# export MPIR_CVAR_SINGLE_HOST_ENABLED=0


dm FI_ PBS

# set -x
# export MPIR_CVAR_REQUEST_ERR_FATAL=1
# export MPICH_DBG_LEVEL=VERBOSE
# export MPICH_DBG_OUTPUT=stdout
# export HYDRA_DEBUG=1
# export PMI_DEBUG=1
# export MPIR_CVAR_CH4_DEBUG=1
# export MPICH_OFI_VERBOSE=1
# set +x

job mpiexec ${*} ./set_affinity_gpu_aurora.sh agent $EXAEPI/examples/inputs.bay agent.fast=1
