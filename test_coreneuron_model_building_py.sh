#!/bin/bash
set -e
module list

source ../toolbox.sh
configfile_bk $1
outputdir=$2

blue_set Simulator CORENEURON $blueconfig

export OMP_NUM_THREADS=1
RUN_PY_TESTS=yes run_blueconfig $blueconfig "--simulate-model=OFF"

RUN_PY_TESTS=yes run_blueconfig $blueconfig "--build-model=OFF"

