#!/bin/zsh -f
set -eu

# LOOP GLOB SUBMIT SH
# All arguments passed to workflow
# See README

THIS=${0:h:A}

source $THIS/settings.sh

PROCS=4
export PPN=1

if (( ${#*} < 2 ))
then
  print "Provide DIR_DATA DIR_INPUTS [PARAMS...]"
  return 1
fi

set -x
which mpiexec agent swift-t
swift-t -m slurm -n $PROCS loop-glob.swift ${*}
