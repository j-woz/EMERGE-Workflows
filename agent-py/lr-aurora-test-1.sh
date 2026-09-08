#!/bin/zsh -f
set -eu

# LOOP REPLICATES AURORA TEST 1 SH
# A particular run with data and parameters

THIS=${0:h:A}

source $THIS/../common/tools.zsh

args OPTZ_IO N - ${*}
export OPTZ_IO

show OPTZ_IO N

A=(
  # The ExaEpi template
  template.cfg
  # The pop.bin
  $THIS/../data-sets/urbanpop_nm.bin
  # The cases.data
  $THIS/../data-sets/NM_Mar16.cases
  # The params.csv
  test_params_$N.csv
  # Number of replicates
  $N
  # Output directory
  ~/E/wozniak/EE-outs/out-test-$OPTZ_IO-$N
)

exists test_params_$N.csv

set -x
$THIS/loop-replicates-aurora.sh $A
