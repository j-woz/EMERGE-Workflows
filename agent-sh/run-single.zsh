#!/bin/zsh
set -eu

USAGE="
RUN SINGLE
Should be called by GNU parallel
CFG  : The CFG to run
"

THIS=${0:A:h}
source $THIS/tools.zsh

zparseopts -D -E h=HELP
args $HELP -H $USAGE -e CFG - ${*}

# For unique GPU assignment:
RANK=$[ PARALLEL_JOBSLOT - 1 ]
source $THIS/affinity.sh

# Exit code:
CODE=0

msgv "START: RANK=%02i $AFFINITY_LABEL $CFG" $RANK

# Use floating-point for time
typeset -F SECONDS
START=$SECONDS

OUTFILE=${CFG%.cfg}.out
printf "run: RANK=%02i $AFFINITY_LABEL CFG=$CFG\n\n" $RANK > $OUTFILE
if =agent $CFG >>& $OUTFILE
then
  : OK
else
  CODE=$?
  msgv "ERROR: RANK=%02i CODE=$CODE from agent" $RANK
fi

STOP=$SECONDS
printf -v DURATION "%0.2f" $[ STOP - START ]
msgv "STOP:  RANK=%02i DURATION=$DURATION" $RANK

return $CODE
