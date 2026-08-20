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

WORK_DIR=/tmp/woz/exaepi
cp -uv template.cfg urbanpop_nm.bin NM_Mar16.cases affinity.sh $WORK_DIR
# =agent
# NOOP=affinity-noop.sh
# AFFINITY=$WORK_DIR/affinity.sh
# if [[ ! -f        $AFFINITY ]] ||
#    [[   $NOOP -nt $AFFINITY ]] {
#   cp -v $NOOP     $AFFINITY
#   chmod u+x       $AFFINITY
# }

PATH=$WORK_DIR:$PATH

swift-t -p -n 10 loop-local-replicates.swift template.cfg $PARAMS 2 \
        urbanpop_nm.bin NM_Mar16.cases results.log
