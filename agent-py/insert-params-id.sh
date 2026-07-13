#!/bin/zsh
set -eu

THIS=${0:h:A}

FILE_IN=$1
FILE_OUT=$2

awk -f $THIS/insert-params-id.awk < $FILE_IN > $FILE_OUT
