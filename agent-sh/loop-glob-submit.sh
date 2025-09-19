#!/bin/zsh -f
set -eu

# LOOP GLOB SUBMIT SH
# All arguments passed to workflow
# See README

THIS=${0:h:A}

source $THIS/settings.sh

if (( ${#*} < 2 ))
then
  print "Provide DIR_DATA DIR_INPUTS [PARAMS...]"
  return 1
fi

export DIR_INPUTS=$2

set -x
which mpiexec agent swift-t
swift-t -m slurm -n $PROCS -t i:copy-inputs.sh loop-glob.swift ${*}
