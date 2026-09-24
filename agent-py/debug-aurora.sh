#!/bin/zsh -f
set -eu

# DEBUG AURORA SH
# See README

THIS=${0:h:A}

source $THIS/../common/tools.zsh
source $THIS/settings-aurora-compute-debug.sh

args TEMPLATE_ORIGIN PARAMS_CSV POP_BIN_ORIGIN CASES_ORIGIN OUTPUT_DIR - ${*}

# Convert user arguments to Absolute paths:
export TEMPLATE_ORIGIN=${TEMPLATE_ORIGIN:A}
PARAMS_CSV=${PARAMS_CSV:A}
export POP_BIN_ORIGIN=${POP_BIN_ORIGIN:A}
export CASES_ORIGIN=${CASES_ORIGIN:A}
export TURBINE_OUTPUT=${OUTPUT_DIR:A}

# Copied locations for direct use or broadcast
export TEMPLATE_CFG=$TURBINE_OUTPUT/template.cfg
export POP_BIN=$TURBINE_OUTPUT/pop.bin
export CASES_DATA=$TURBINE_OUTPUT/cases.data

export LOCAL_DIR=/tmp/$USER/exaepi
export AGENT_ORIGIN==agent

source $THIS/stage-data.sh

# export TURBINE_LOG=1

export TURBINE_LEADER_HOOK_STARTUP=$( cat $THIS/hook.tcl )

export LOCAL_DIR=/tmp/$USER/exaepi

ENVS=( -e TEMPLATE_CFG
       -e PYTHONPATH
     )

PATH=$LOCAL_DIR:$THIS:$PATH
export PYTHONPATH=$THIS

set -x
which mpiexec swift-t
swift-t -m pbs -n $PROCS $ENVS debug-hook.swift
