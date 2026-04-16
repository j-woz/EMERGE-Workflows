
# SETTINGS PERLMUTTER SH
# For multi-MPI runs on Perlmutter

# Software locations on Perlmutter:

SFW=/global/cfs/cdirs/m5071/sfw
EXAEPI=$SFW/ExaEpi-mpich
MPICH=$SFW/mpich-4.3.0
SWIFT=$SFW/swift-t

PATH=$THIS:$EXAEPI/bin:$SWIFT/stc/bin:$MPICH/bin:$PATH

# Swift/T scheduler settings follow:

# This is the old EMERGE project (early 2025):
# export PROJECT=m3623_g
# This is the EMERGE ALCC from 2025-08:
export PROJECT=m5071

# Edit this based on your workload!
# See https://docs.nersc.gov/jobs/policy
# Perlmutter limits queue debug to 8 nodes, 30 minutes
# Generally, schedulers prefer more nodes, smaller walltime
export QUEUE=debug
# export QUEUE=regular
export WALLTIME=00:05:00
# PROCS=128
PROCS=4
export PPN=1

# SLURM GPU settings:
# This inserts the SBATCH directive into the job script:
export TURBINE_DIRECTIVE="
#SBATCH -C gpu
#SBATCH --gpus-per-node=4
"

# This is needed for our plain MPICH configuration:
export TURBINE_PRELAUNCH="export LD_LIBRARY_PATH=$MPICH/lib:\${LD_LIBRARY_PATH:-}"
