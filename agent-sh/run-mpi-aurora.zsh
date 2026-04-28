#!/bin/zsh -f
set -eu

USAGE="
RUN MPI AURORA
Run agent once from within an interactive session
"

THIS=${0:h:A}
source $THIS/tools.zsh

zparseopts -D -E h=HELP
args $HELP -H $USAGE -e INPUT_CFG AGENT_PROCS - ${*}

source $THIS/settings-aurora-compute.sh

which mpiexec agent

START=$SECONDS
(){
  set -x
  mpiexec -n $AGENT_PROCS \
          aff-aurora-mpich.sh agent $INPUT_CFG agent.fast=1
}
STOP=$SECONDS

print "TIME:" $[ STOP - START ]

# Perlmutter:
# Works w/w/o srun:
# Must use srun to get on compute node!
# UI session is on login node!
# srun mpiexec -launcher fork -n 2 agent $EXAEPI/examples/inputs.bay
