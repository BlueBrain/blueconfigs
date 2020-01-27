#!/bin/bash
set -e
source ../toolbox.sh
configfile_bk $1
outputdir=$2

blue_set Simulator CORENEURON $blueconfig
blue_comment "Report soma" $blueconfig

export OMP_NUM_THREADS=1
run_blueconfig $blueconfig
