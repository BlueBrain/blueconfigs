#!/bin/bash
set -e
spack load reportinglib
source ../toolbox.sh
configfile_bk $1
outputdir=$2

blue_set Simulator CORENEURON $blueconfig
blue_comment "Report soma" $blueconfig

export OMP_NUM_THREADS=1
source ./save-restore.sh $blueconfig $outputdir
