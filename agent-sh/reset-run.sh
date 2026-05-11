#!/bin/zsh
set -eu

USAGE="
RUN_DIR:   The workflow run directory
Moves all outputs in RUN_DIR to archive under given RUN_DIR
"

THIS=${0:A:h}
source $THIS/tools.zsh

zparseopts -D -E h=HELP

args $HELP -H $USAGE -ev RUN_DIR - ${*}

if [[ ! -d $RUN_DIR ]] abort "does not exist: RUN_DIR='$RUN_DIR'"

cd $RUN_DIR

mkdir -pv Archive

# Allow empty globs:
setopt NULLGLOB
rm0 Backtrace*
FILES=(
  # Application data:
  *.stdout *.stderr *.dat
  # Swift/T artifacts:
  jobid.txt*  *.sh turbine.log* turbine-env.txt* *.tic
)

# Don't unlink output.txt for performance:
if (( $#FILES > 0 )) {
  mv --backup=numbered $FILES     Archive
  cp --backup=numbered output.txt Archive
  echo > output.txt
}

