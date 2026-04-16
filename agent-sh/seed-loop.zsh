#!/bin/zsh
set -eu

# SEED LOOP

USAGE="
COUNT:     Number of iterations
INPUT_CFG: The original input file to use as a base
RUN_DIR:   The workflow run directory
"

THIS=${0:A:h}
source $THIS/tools.zsh

zparseopts -D -E h=HELP

args $HELP -H $USAGE -ev COUNT INPUT_CFG RUN_DIR - ${*}

mkdir -pv $RUN_DIR

for (( i=0 ; i < COUNT ; i++ ))
do
  SEED=$RANDOM
  printf -v NAME "seed_%02i_%05i" $i $SEED
  {
    print "# $NAME generated ${(%)DATE_FMT}\n"
    sed -f $THIS/seed-loop.sed $INPUT_CFG
    print "agent.seed = $SEED"
    print "diag.output_filename = $RUN_DIR/$NAME.dat"
  } >> $RUN_DIR/$NAME.cfg
done
