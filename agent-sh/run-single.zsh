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

msgv "START: RANK=%02i ZE_AFFINITY_MASK=$ZE_AFFINITY_MASK $CFG" $RANK

# Use floating-point for time
typeset -F SECONDS
START=$SECONDS

OUTFILE=${CFG%.cfg}.out
if =agent $CFG >& $OUTFILE
then
  : OK
else
  msg "ERROR: RANK=$RANK"
  CODE=1
fi

STOP=$SECONDS
printf -v DURATION "%0.2f" $[ STOP - START ]
msgv "STOP:  RANK=%02i DURATION=$DURATION" $RANK

return $CODE
