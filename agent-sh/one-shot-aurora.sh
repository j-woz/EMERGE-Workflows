#!/bin/zsh
set -eu

# ONE SHOT AURORA

THIS=${0:h:A}
source $THIS/settings-aurora-compute.sh

: ${PROCS:=2} ${PPN:=2}
export PROCS PPN

source $THIS/settings-aurora-compute.sh

which swift-t
swift-t -m pbs one-shot.swift $*
