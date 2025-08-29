#!/bin/zsh -f
set -eu

THIS=${0:h:A}

source $THIS/settings.sh

PROCS=4
export PPN=1

INPUTS=( $THIS/inputs-5.bay
         $THIS/inputs-6.bay
         $THIS/inputs-7.bay
       )

set -x
which mpiexec agent swift-t
swift-t -m slurm -n $PROCS loop.swift $INPUTS
