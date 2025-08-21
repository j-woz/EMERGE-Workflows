#!/bin/zsh

# ONE SHOT
# Run agent once from within an interactive session

source /usr/share/lmod/lmod/init/zsh

set -eu

module load cudatoolkit

MPICH=/global/cfs/cdirs/m3623/wozniak/sfw/mpich-4.3.0
EXAEPI=/global/u1/w/wozniak/proj/ExaEpi.mpich

PATH=$MPICH/bin:$EXAEPI/build/bin:$PATH

srun mpiexec -n 2 agent $EXAEPI/examples/inputs.bay
