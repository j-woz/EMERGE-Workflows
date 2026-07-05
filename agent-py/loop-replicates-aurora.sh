#!/bin/zsh -f
set -eu

# LOOP REPLICATES AURORA SH
# All arguments passed to workflow
# See README

THIS=${0:h:A}

source $THIS/settings-aurora-compute.sh

if (( ${#*} != 4 ))
then
  print "Provide TEMPLATE_CSV PARAMS_CSV REPLICATES OUTPUT_DIR"
  return 1
fi

# Convert user arguments to Absolute paths:
export TEMPLATE_CFG=${1:A}
PARAMS_CSV=${2:A}
REPLICATES=$3
export TURBINE_OUTPUT=${4:A}

# export TURBINE_LOG=1

export TURBINE_LEADER_HOOK_STARTUP=$( cat $THIS/hook.tcl )

LOCAL_DIR=/tmp/$USER/exaepi

ENVS=( -e TEMPLATE_CFG
       -e PYTHONPATH
     )

PATH=$LOCAL_DIR:$THIS:$PATH

set -x
which mpiexec swift-t
swift-t -m pbs -n $PROCS $ENVS loop-local-replicates.swift \
        $LOCAL_DIR/template.cfg $PARAMS_CSV $REPLICATES \
        urbanpop_nm.bin NM_Mar16.cases \
        $TURBINE_OUTPUT/results.log
# template.cfg test-3.csv 2 \
#         urbanpop_nm.bin NM_Mar16.cases results.log
