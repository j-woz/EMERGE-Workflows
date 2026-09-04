
# SETTINGS AURORA SH
# For runs on Aurora
# Assumes THIS has been set

# Software locations on Aurora:

SFW=/lus/flare/projects/EpiCalib/sfw
EXAEPI=$SFW/ExaEpi_mpich-git_2026-06-10
MPICH=$SFW/mpich-git
SWIFT=$SFW/swift-t/2026-09-02

PATH=$THIS:$EXAEPI/bin:$SWIFT/stc/bin:$MPICH/bin:$PATH

# Swift/T scheduler settings follow:

# This is the EMERGE project:
export PROJECT=EpiCalib

# Edit this based on your workload!
# Aurora limits queue debug to 1 hour
# Generally, schedulers prefer more nodes, smaller walltime
export QUEUE=${QUEUE:-debug}
# export QUEUE=regular
export WALLTIME=${WALLTIME:-00:05:00}
# PROCS=128
PROCS=${PROCS:-2}
export PPN=${PPN:-2}

# OPTZ_IO: Allowed values: "IO", "I", "O", ""
# "I": Optimize inputs "O": Optimize outputs
# Defaults to "IO", optimizing both
export OPTZ_IO=${OPTZ_IO:-IO}

# See https://docs.alcf.anl.gov/aurora/running-jobs-aurora/#submitting-a-job
export TURBINE_DIRECTIVE="#PBS -l filesystems=home:flare"

# For libimf
export TURBINE_PRELAUNCH="export LD_LIBRARY_PATH=/opt/aurora/26.181.0/oneapi/compiler/latest/lib:\${LD_LIBRARY_PATH:-}"

PS4='+ '
