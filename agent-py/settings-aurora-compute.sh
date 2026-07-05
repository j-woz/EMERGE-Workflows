
# SETTINGS AURORA SH
# For runs on Aurora
# Assumes THIS has been set

# Software locations on Aurora:

SFW=/lus/flare/projects/EpiCalib/sfw
EXAEPI=$SFW/ExaEpi_mpich-git_2026-04-24
MPICH=$SFW/mpich-git
SWIFT=$SFW/swift-t/2026-04-16

PATH=$THIS:$EXAEPI/bin:$SWIFT/stc/bin:$MPICH/bin:$PATH

# Swift/T scheduler settings follow:

# This is the EMERGE project:
export PROJECT=EpiCalib

export PYTHONPATH=$THIS

# Edit this based on your workload!
# Aurora limits queue debug to 1 hour
# Generally, schedulers prefer more nodes, smaller walltime
export QUEUE=${QUEUE:-debug}
# export QUEUE=regular
export WALLTIME=${WALLTIME:-00:05:00}
# PROCS=128
PROCS=${PROCS:-2}
export PPN=${PPN:-2}

# See https://docs.alcf.anl.gov/aurora/running-jobs-aurora/#submitting-a-job
export TURBINE_DIRECTIVE="#PBS -l filesystems=home:flare"

# # This is needed for our plain MPICH configuration:
# export TURBINE_PRELAUNCH="export LD_LIBRARY_PATH=$MPICH/lib:\${LD_LIBRARY_PATH:-}"

PS4='+ '
