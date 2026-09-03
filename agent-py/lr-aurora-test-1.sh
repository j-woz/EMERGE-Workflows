#!/bin/zsh -f
set -eu

# LOOP REPLICATES AURORA TEST 1 SH
# A particular run with data and parameters

THIS=${0:h:A}

source $THIS/../common/tools.zsh

export OPTZ_IO=IO

A=(
  # The ExaEpi template
  template.cfg
  # The pop.bin
  $THIS/../data-sets/urbanpop_nm.bin
  # The cases.data
  $THIS/../data-sets/NM_Mar16.cases
  # The params.csv
  test_params_100.csv
  # Number of replicates
  100
  # Output directory
  ~/E/wozniak/EE-outs/out-test-100-_O
)

set -x
$THIS/loop-replicates-aurora.sh $A
