#!/bin/bash
set -eu

# Default PROCS=2
PROCS=${1:-2}

export TURBINE_SRAND=$( date +%s )
swift-t -n $PROCS copies.swift ${*}
