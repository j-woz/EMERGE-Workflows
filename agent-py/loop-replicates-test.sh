#!/bin/zsh
set -eu

# LOOP REPLICATES TEST
# Local test use case

THIS=${0:A:h}
source $THIS/../common/tools.zsh

export PYTHONPATH=$PWD
export ADLB_DEBUG=0

print
print "loop-replicates-test ..."
print

args TEMPLATE_ORIGIN POP_BIN_ORIGIN CASES_ORIGIN PARAMS_CSV_ORIGIN \
     TURBINE_OUTPUT REPLICATES SEED_INIT STREAMS - ${*}

if ! =which agent
then
  error "Add ExaEpi agent to PATH!"
fi

export TURBINE_OUTPUT
export OPTZ_IO="IO"
export LOCAL_DIR=/tmp/woz/exaepi
export AGENT_ORIGIN==agent

show TURBINE_OUTPUT

mkdir -pv $TURBINE_OUTPUT
mkdir -pv /tmp/woz/exaepi

# Convert user arguments to Absolute paths:
export TEMPLATE_ORIGIN=${TEMPLATE_ORIGIN:A}
export POP_BIN_ORIGIN=${POP_BIN_ORIGIN:A}
export CASES_ORIGIN=${CASES_ORIGIN:A}
export PARAMS_CSV=${PARAMS_CSV_ORIGIN:A}

# Copied locations for direct use or broadcast
export TEMPLATE_CFG=$TURBINE_OUTPUT/template.cfg
export POP_BIN=$TURBINE_OUTPUT/pop.bin
export CASES_DATA=$TURBINE_OUTPUT/cases.data

# Stage data
mkdir -pv $TURBINE_OUTPUT
cp -uv $TEMPLATE_ORIGIN $TEMPLATE_CFG
cp -uv $POP_BIN_ORIGIN  $POP_BIN
cp -uv $CASES_ORIGIN    $CASES_DATA
cp -uv $AGENT_ORIGIN $THIS/affinity.sh $TURBINE_OUTPUT
bak $TURBINE_OUTPUT/data-origins.txt
{
  # Record original data locations for provenance
  msg "DATA ORIGINS"
  show AGENT_ORIGIN TEMPLATE_ORIGIN POP_BIN_ORIGIN CASES_ORIGIN \
       OPTZ_IO
} > $TURBINE_OUTPUT/data-origins.txt

export PATH=$THIS:$PATH

if [[ $OPTZ_IO == *I* ]] {
  export INPUT_DIR=$LOCAL_DIR
  export TURBINE_LEADER_HOOK_STARTUP=$( cat $THIS/hook.tcl )
} else {
  export INPUT_DIR=$TURBINE_OUTPUT
}

export PATH=$INPUT_DIR:$PATH

WORKFLOW_ARGS=(
  $TURBINE_OUTPUT/results
  $PARAMS_CSV
  --replicates=$REPLICATES
  --seed_init=$SEED_INIT
  --streams=$STREAMS
)

set -x
cd $TURBINE_OUTPUT
pwd
which swift-t
swift-t -p -n 4 -I $THIS \
        $THIS/loop-local-replicates.swift $WORKFLOW_ARGS
