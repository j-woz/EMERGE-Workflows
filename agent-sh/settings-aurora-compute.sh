
# SETTINGS AURORA SH
# For runs on Aurora

# Software locations on Aurora:

SFW=/lus/flare/projects/EpiCalib/sfw
EXAEPI=$SFW/ExaEpi_mpich-git_2026-04-24
MPICH=$SFW/mpich-git
SWIFT=$SFW/swift-t/2026-04-16

PATH=$THIS:$EXAEPI/bin:$SWIFT/stc/bin:$MPICH/bin:$PATH

# Swift/T scheduler settings follow:

# This is the EMERGE project:
export PROJECT=EpiCalib

# Edit this based on your workload!
# See
# Aurora limits queue debug to ???
# Generally, schedulers prefer more nodes, smaller walltime
export QUEUE=debug
# export QUEUE=regular
export WALLTIME=00:05:00
# PROCS=128
PROCS=2
export PPN=2

# See https://docs.alcf.anl.gov/aurora/running-jobs-aurora/#submitting-a-job
export TURBINE_DIRECTIVE="#PBS -l filesystems=home:flare"

# # This is needed for our plain MPICH configuration:
# export TURBINE_PRELAUNCH="export LD_LIBRARY_PATH=$MPICH/lib:\${LD_LIBRARY_PATH:-}"
