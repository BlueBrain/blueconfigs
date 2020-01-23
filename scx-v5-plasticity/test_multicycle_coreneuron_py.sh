#!/bin/bash
set -e
source ../toolbox.sh
configfile_bk $1

blue_set Simulator CORENEURON $blueconfig
head -n30 $blueconfig

export OMP_NUM_THREADS=1

RUN_PY_TESTS=yes run_blueconfig $blueconfig "--modelbuilding-steps=2"
