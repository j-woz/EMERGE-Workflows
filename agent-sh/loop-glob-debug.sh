#!/bin/zsh -f
set -eu

# LOOP GLOB DEBUG SH
# All arguments passed to workflow
# See README

THIS=${0:h:A}

source $THIS/settings-perlmutter-local.sh

PROCS=4

set -x
which swift-t
swift-t -n $PROCS loop-glob.swift ${*}
