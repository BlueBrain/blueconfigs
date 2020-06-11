#!/bin/bash
set -e
module load unstable reportinglib
module list

source ../toolbox.sh
configfile_bk $1
outputdir=$2

blue_set Simulator CORENEURON $blueconfig
head -n 30 $blueconfig

export OMP_NUM_THREADS=1
#test with different seeds in save and restore
source ../_util/save-restore.sh $blueconfig $outputdir 767740 222 333

#assign a different reference spikes
echo "out.coreneuron.differentseed.sorted" > $outputdir/ref_spikes.txt
