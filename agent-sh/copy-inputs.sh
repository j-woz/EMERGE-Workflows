#!/bin/sh
set -eu

# COPY INPUTS SH
# See README

mkdir -pv $TURBINE_OUTPUT/inputs
cp -r $DIR_INPUTS/* $TURBINE_OUTPUT/inputs
