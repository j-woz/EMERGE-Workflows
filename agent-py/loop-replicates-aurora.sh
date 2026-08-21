#!/bin/zsh -f
set -eu

# LOOP REPLICATES AURORA SH
# All arguments passed to workflow
# See README

THIS=${0:h:A}

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

source $THIS/settings-aurora-compute.sh

# export TURBINE_LOG=1

export LOCAL_DIR=/tmp/$USER/exaepi

if [[ $OPTZ_IO == *I* ]] {
  export INPUT_DIR=$LOCAL_DIR
  export TURBINE_LEADER_HOOK_STARTUP=$( cat $THIS/hook.tcl )
} else {
  export INPUT_DIR=$TURBINE_OUTPUT
  cp -uv =agent =affinity.sh $TURBINE_OUTPUT
  cp -uv $TEMPLATE_CFG       $TURBINE_OUTPUT/template.cfg
}

export PYTHONPATH=$LOCAL_DIR:$THIS:${PYTHONPATH:-}

ENVS=( -e TEMPLATE_CFG
       -e PYTHONPATH
       -e OPTZ_IO
       -e LOCAL_DIR
       -e INPUT_DIR
     )

PATH=$INPUT_DIR:$TURBINE_OUTPUT:$THIS:$PATH

set -x
which mpiexec swift-t
swift-t -m pbs -n $PROCS $ENVS loop-local-replicates.swift \
        $LOCAL_DIR/template.cfg $PARAMS_CSV $REPLICATES \
        urbanpop_nm.bin NM_Mar16.cases \
        $TURBINE_OUTPUT/results.log
# template.cfg test-3.csv 2 \
#         urbanpop_nm.bin NM_Mar16.cases results.log
