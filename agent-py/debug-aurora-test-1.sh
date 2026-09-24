#!/bin/zsh -f
set -eu

# DEBUG AURORA TEST 1 SH
# See README

THIS=${0:h:A}

source $THIS/../common/tools.zsh

FOUND=0
for (( JOBN=0 ; JOBN < 1000 ; JOBN++ ))
do
  printf -v TURBINE_JOBNAME "DBG-%03i" $JOBN
  OUTPUT_DIR=( ~/E/wozniak/EE-outs/out-$TURBINE_JOBNAME )
  if [[ ! -d $OUTPUT_DIR ]] { FOUND=1 ; break }
done
if (( ! FOUND )) abort "No free OUTPUT_DIR options!"
export TURBINE_JOBNAME

PARAMS=/lus/flare/projects/EpiCalib/wozniak/EE-inputs/GSA_Saltelli_m18_inputs.csv

A=( $THIS/template.cfg
    $PARAMS
    $THIS/../data-sets/urbanpop_nm.bin
    $THIS/../data-sets/NM_Mar16.cases
    $OUTPUT_DIR
  )

set -x
$THIS/debug-aurora.sh $A
