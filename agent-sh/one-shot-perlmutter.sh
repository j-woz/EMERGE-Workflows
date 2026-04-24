#!/bin/zsh
set -eu

THIS=${0:h:A}
source $THIS/settings.sh

export PPN=1

INPUTS=/global/cfs/cdirs/m5071/sfw/ExaEpi-mpich/examples/inputs.bay

which swift-t
swift-t -m slurm -n 4 one-shot.swift $INPUTS
