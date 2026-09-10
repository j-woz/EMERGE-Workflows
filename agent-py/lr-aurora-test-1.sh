#!/bin/zsh -f
set -eu

# LOOP REPLICATES AURORA TEST 1 SH
# A particular run with data and parameters

THIS=${0:h:A}

source $THIS/../common/tools.zsh

# SET: train, valid, test
# N: Number of replicates
args OPTZ_IO SET N - ${*}
export OPTZ_IO

show OPTZ_IO SET N

# The params.csv
PARAMS=${SET}_params_$N.csv

exists $PARAMS

A=(
  # The ExaEpi template
  template.cfg
  # The pop.bin
  $THIS/../data-sets/urbanpop_nm.bin
  # The cases.data
  $THIS/../data-sets/NM_Mar16.cases
  $PARAMS
  $N
  # Output directory
  ~/E/wozniak/EE-outs/out-$SET-$OPTZ_IO-$N
)

set -x
$THIS/loop-replicates-aurora.sh $A
