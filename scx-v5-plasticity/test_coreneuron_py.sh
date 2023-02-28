#!/bin/bash
set -e
module load py-neurodamus/develop
module list

source ../toolbox.sh
configfile_bk $1
outputdir=$2

blue_set Simulator CORENEURON $blueconfig

export OMP_NUM_THREADS=1
RUN_PY_TESTS=yes run_blueconfig $blueconfig

