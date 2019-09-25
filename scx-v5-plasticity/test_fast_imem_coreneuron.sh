#!/bin/bash
set -e
set -x
source ../toolbox.sh
#blue_set Simulator CORENEURON $blueconfig
blue_uncomment "Report AllCompartmentsIMembrane" $blueconfig

export OMP_NUM_THREADS=1

head -n30 $blueconfig
run_blueconfig $blueconfig

cp ${2}/AllCompartmentsIMembrane.bbp /gpfs/bbp.cscs.ch/home/magkanar/proj16/