#!/bin/zsh
set -eu

# INSERT PARAMS ID
# Copies the original CSV, inserting a leading column "params_id
# that is simply a record number.

THIS=${0:h:A}

FILE_IN=$1
FILE_OUT=$2

awk -f $THIS/insert-params-id.awk < $FILE_IN > $FILE_OUT
