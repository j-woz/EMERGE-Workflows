#!/bin/zsh -f
set -eu

# LOOP GLOB SUBMIT SH
# All arguments passed to workflow
# See README

THIS=${0:h:A}

source $THIS/settings.sh

if (( ${#*} != 1 ))
then
  print "Provide DIR_INPUTS"
  return 1
fi

# Convert user argument to Absolute path:
export DIR_INPUTS=${1:A}

set -x
which mpiexec agent swift-t
swift-t -m slurm -n $PROCS -t i:copy-inputs.sh loop-glob.swift ${*}
