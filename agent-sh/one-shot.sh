#!/bin/zsh

# ONE SHOT
# Run agent once from within an interactive session

source /usr/share/lmod/lmod/init/zsh

set -eu

THIS=${0:h:A}
source $THIS/settings.sh

module load cudatoolkit

pe > pe.log

# Works w/w/o srun:
# Must use srun to get on compute node!
# UI session is on login node!
set -x
srun mpiexec -launcher fork -n 2 agent $EXAEPI/examples/inputs.bay
