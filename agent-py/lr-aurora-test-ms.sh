#!/bin/zsh -f
set -eu

# LOOP REPLICATES AURORA TEST 3 SH
# A particular run with data and parameters
# Includes seed_init and multi-stream capabilities

THIS=${0:h:A}

source $THIS/../common/tools.zsh

# N:         Number of replicates
# SEED_INIT:
args N SEED_INIT - ${*}

# Hard-code OPTZ_IO and PARAMS for this campaign:
export OPTZ_IO=IO
show OPTZ_IO SET N
# The params.csv
PARAMS=/lus/flare/projects/EpiCalib/wozniak/EE-inputs/GSA_Saltelli_m18_inputs.csv
exists $PARAMS

printf -v JOBNAME "%i-%02i" $N $SEED_INIT
export TURBINE_JOBNAME=EE-$JOBNAME

A=(
  # The ExaEpi template
  template.cfg
  # The pop.bin
  $THIS/../data-sets/urbanpop_nm.bin
  # The cases.data
  $THIS/../data-sets/NM_Mar16.cases
  $PARAMS
  # Output directory
  ~/E/wozniak/EE-outs/out-1B-$JOBNAME
  $N
  $SEED_INIT
)

set -x
$THIS/loop-replicates-aurora.sh $A
