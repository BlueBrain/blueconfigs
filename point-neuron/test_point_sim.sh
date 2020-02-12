#!/bin/bash
set -ex
module load py-neurodamus
module list

source ../toolbox.sh
configfile_bk BlueConfig.point
outputdir="${2:-output}"
blue_set OutputRoot "$outputdir" $blueconfig

rm -rf x86_64 hippocampus mod

# Clone hippocampus with adex.mod
git clone --recursive -b sandbox/magkanar/pointneuron_merge ssh://bbpcode.epfl.ch/sim/models/hippocampus
mkdir mod
cp hippocampus/mod/adex.mod mod
build_neurodamus.sh mod

bb5_run ./x86_64/special -mpi -python $NEURODAMUS_PYTHON/init.py --configFile=$blueconfig --verbose
