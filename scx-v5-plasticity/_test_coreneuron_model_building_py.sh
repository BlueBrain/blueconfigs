#!/bin/bash
set -e
module load python-dev
module list

source ../toolbox.sh
configfile_bk $1
outputdir=$2

blue_set Simulator CORENEURON $blueconfig

export OMP_NUM_THREADS=1
RUN_PY_TESTS=yes run_blueconfig $blueconfig "--build-model"

RUN_PY_TESTS=yes run_blueconfig $blueconfig "--run-sim"

