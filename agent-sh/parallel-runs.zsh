#!/bin/zsh
set -eu

USAGE="
PARALLEL RUNS
Runs the seed-loop workflow using GNU parallel
Calls run-single.zsh to run ExaEpi

RUN_DIR:   The workflow run directory full of input CFGs
           This is created by seed-loop.zsh
CPUS:      Max parallelism - sync with affinity.sh!
"

THIS=${0:A:h}
source $THIS/tools.zsh

zparseopts -D -E h=HELP

args $HELP -H $USAGE -ev RUN_DIR CPUS - ${*}

cd $RUN_DIR

print -l *.cfg > parallel.list

(
  set -x
  parallel -j $CPUS --arg-file parallel.list run-single.zsh
) |& tee parallel.out
