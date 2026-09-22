#!/bin/zsh -f
set -eu

# LOOP REPLICATES TEST 3 SH
# A particular run with data and parameters
# Includes seed_init and multi-stream capabilities

THIS=${0:h:A}

source $THIS/../common/tools.zsh

# N:         Number of replicates
# SEED_INIT:
args N SEED_INIT STREAMS - ${*}

# Hard-code OPTZ_IO and PARAMS for this campaign:
export OPTZ_IO=IO
show OPTZ_IO SET N
# The params.csv
PARAMS=$THIS/test_params_5.csv
exists $PARAMS

A=(
  # The ExaEpi template
  $THIS/template.cfg
  # The pop.bin
  $THIS/../data-sets/urbanpop_nm.bin
  # The cases.data
  $THIS/../data-sets/NM_Mar16.cases
  $PARAMS
  # Output directory
  $THIS/output
  $N
  $SEED_INIT
  $STREAMS
)

set -x
$THIS/loop-replicates-test.sh $A
