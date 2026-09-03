#!/bin/zsh
set -eu

# RESET OUTPUT
# Reset an output directory

THIS=${0:h:A}

source $THIS/../common/tools.zsh

args DIR - ${*}

if [[ ! -d $DIR ]] abort "Does not exist: $DIR"

rm0 -v $DIR/*.tic $DIR/results.log
rm0 -r $DIR/runs

bak $DIR/jobid.txt
bak $DIR/turbine-env.txt
bak $DIR/turbine.log
bak $DIR/turbine-pbs.sh
bak -v $DIR/output.txt
