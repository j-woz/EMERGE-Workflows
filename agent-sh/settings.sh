
# SETTINGS SH
# For multi-MPI runs on Perlmutter

# Software locations on Perlmutter:

SFW=/global/cfs/cdirs/m5071/sfw
EXAEPI=$SFW/ExaEpi-mpich
MPICH=$SFW/mpich-4.3.0
SWIFT=$SFW/swift-t

PATH=$THIS:$EXAEPI/bin:$SWIFT/stc/bin:$MPICH/bin:$PATH

# Swift/T scheduler settings follow:

# This is the old project (early 2025):
# export PROJECT=m3623_g
# This is the ALCC from 2025-08:
export PROJECT=m5071

export QUEUE=debug
# export QUEUE=regular
export WALLTIME=00:05:00
# PROCS=128
PROCS=4
export PPN=1

# This inserts the SBATCH directive into the job script:
export TURBINE_DIRECTIVE="
#SBATCH -C gpu
#SBATCH --gpus-per-node=4
"
