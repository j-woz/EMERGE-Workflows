#!/bin/zsh -f
set -eu

# LOOP REPLICATES AURORA SH
# See README

THIS=${0:h:A}

source $THIS/../common/tools.zsh

args TEMPLATE_ORIGIN POP_BIN_ORIGIN CASES_ORIGIN PARAMS_CSV_ORIGIN \
     REPLICATES SEED_INIT OUTPUT_DIR - ${*}

# Convert user arguments to Absolute paths:
export TEMPLATE_ORIGIN=${TEMPLATE_ORIGIN:A}
export POP_BIN_ORIGIN=${POP_BIN_ORIGIN:A}
export CASES_ORIGIN=${CASES_ORIGIN:A}
export PARAMS_CSV=${PARAMS_CSV_ORIGIN:A}
export TURBINE_OUTPUT=${OUTPUT_DIR:A}

# Copied locations for direct use or broadcast
export TEMPLATE_CFG=$TURBINE_OUTPUT/template.cfg
export POP_BIN=$TURBINE_OUTPUT/pop.bin
export CASES_DATA=$TURBINE_OUTPUT/cases.data

JOBNAME_DFLT="EE-$OPTZ_IO"
export TURBINE_JOBNAME=${TURBINE_JOBNAME:-$JOBNAME_DFLT}

source $THIS/settings-aurora-compute.sh

# Customizable settings
export OPTZ_IO=${OPTZ_IO:-IO}
export LOCAL_DIR=/tmp/$USER/exaepi
export AGENT_ORIGIN==agent

source $THIS/stage-data.sh

if [[ $OPTZ_IO == *I* ]] {
  export INPUT_DIR=$LOCAL_DIR
  export TURBINE_LEADER_HOOK_STARTUP=$( cat $THIS/hook.tcl )
} else {
  export INPUT_DIR=$TURBINE_OUTPUT
}

show INPUT_DIR

export PATH=$INPUT_DIR:$PATH
export PYTHONPATH=$LOCAL_DIR:$THIS:${PYTHONPATH:-}

ENVS=( -e TEMPLATE_CFG
       -e PYTHONPATH
       -e OPTZ_IO
       -e LOCAL_DIR
       -e INPUT_DIR
     )

WORKFLOW_ARGS=(
  $PARAMS_CSV
  $TURBINE_OUTPUT/results
  --replicates=$REPLICATES
  --seed_init=$SEED_INIT
)

set -x
which swift-t
swift-t -m pbs -n $PROCS $ENVS loop-local-replicates.swift \
        $WORKFLOW_ARGS
