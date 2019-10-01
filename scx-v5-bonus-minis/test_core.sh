#!/bin/bash
set -e
module load python-dev
module list

source ../toolbox.sh
configfile_bk $1
outputdir=$2

blue_set Simulator CORENEURON $blueconfig

export OMP_NUM_THREADS=1
run_blueconfig $blueconfig

