#!/bin/bash
set -e

source ../toolbox.sh
configfile_bk $1
outputdir=$2

blue_set Simulator CORENEURON $blueconfig

export OMP_NUM_THREADS=1
n=3 run_simulation $blueconfig

