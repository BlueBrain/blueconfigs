#!/bin/bash
set -e
module load reportinglib
module list

source ../toolbox.sh
configfile_bk $1
outputdir=$2

blue_set Simulator CORENEURON $blueconfig
blue_comment "Report soma" $blueconfig
head -n 30 $blueconfig

export OMP_NUM_THREADS=1
source ./save-restore.sh $blueconfig $outputdir
