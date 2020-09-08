#!/bin/bash
set -e

source ../toolbox.sh
configfile_bk $1
outputdir=$2

blue_set Simulator CORENEURON $blueconfig

export OMP_NUM_THREADS=1

# run without neurodamus-py
RUN_PY_TESTS=no run_blueconfig $blueconfig

# run with neurodamus-py
#RUN_PY_TESTS=yes run_blueconfig $blueconfig
