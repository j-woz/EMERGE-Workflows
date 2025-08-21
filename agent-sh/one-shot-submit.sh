#!/bin/zsh
set -eu

THIS=${0:h:A}

EXAEPI=$HOME/proj/ExaEpi.mpich
MPICH=$HOME/sfw/mpich-4.3.0
SWIFT=$HOME/Public/sfw/compute/swift-t/2025-08-14

PATH=$THIS:$EXAEPI/build/bin:$SWIFT/stc/bin:$MPICH/bin:$PATH

export PROJECT=m3623_g
export QUEUE=debug
export WALLTIME=05:00
export PPN=8

export TURBINE_DIRECTIVE="#SBATCH -C gpu"

which swift-t
swift-t -m slurm -n 8 one-shot.swift ~/proj/ExaEpi.mpich/examples/inputs.bay
