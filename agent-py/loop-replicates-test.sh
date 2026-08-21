#!/bin/zsh
set -eu

# LOOP REPLICATES TEST
# Local test use case

THIS=${0:A:h}
source $THIS/../common/tools.zsh

export PYTHONPATH=$PWD
export ADLB_DEBUG=0

args PARAMS - ${*}

mkdir -pv /tmp/woz/exaepi

if ! which agent > /dev/null
then
  error "Add ExaEpi agent to PATH!"
fi

export OPTZ_IO="O"
export TEMPLATE_CFG=$THIS/template.cfg
export DATA_DIR=$THIS/data-sets
export LOCAL_DIR=/tmp/woz/exaepi
export TURBINE_OUTPUT=$THIS/turbine-output
export AGENT_ORIGIN==agent

export PATH=$THIS:$PATH

mkdir -p $TURBINE_OUTPUT

if [[ $OPTZ_IO == *I* ]] {
  export INPUT_DIR=$LOCAL_DIR
  export TURBINE_LEADER_HOOK_STARTUP=$( cat $THIS/hook.tcl )
} else {
  export INPUT_DIR=$TURBINE_OUTPUT
  cp -uv $DATA_DIR/{NM_Mar16.cases,urbanpop_nm.bin} \
         $AGENT_ORIGIN $THIS/affinity.sh \
         $TURBINE_OUTPUT
  cp -uv $TEMPLATE_CFG       $TURBINE_OUTPUT/template.cfg
}

export PATH=$INPUT_DIR:$PATH

# =agent
# NOOP=affinity-noop.sh
# AFFINITY=$WORK_DIR/affinity.sh
# if [[ ! -f        $AFFINITY ]] ||
#    [[   $NOOP -nt $AFFINITY ]] {
#   cp -v $NOOP     $AFFINITY
#   chmod u+x       $AFFINITY
# }

swift-t -p -n 10 loop-local-replicates.swift template.cfg $PARAMS 2 \
        urbanpop_nm.bin NM_Mar16.cases results.log
