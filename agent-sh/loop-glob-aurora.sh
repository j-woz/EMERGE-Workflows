#!/bin/zsh -f
set -eu

# LOOP GLOB AURORA SH
# All arguments passed to workflow
# See README
# DOES NOT WORK YET!

THIS=${0:h:A}

source $THIS/settings-aurora-compute.sh

if (( ${#*} != 1 ))
then
  print "Provide DIR_INPUTS"
  return 1
fi

# Convert user argument to Absolute path:
# This is used by copy-inputs.sh
export DIR_INPUTS=${1:A}

export TURBINE_LOG=1

set -x
which mpiexec agent swift-t
swift-t -m pbs -n $PROCS -t i:copy-inputs.sh loop-glob.swift ${*}
