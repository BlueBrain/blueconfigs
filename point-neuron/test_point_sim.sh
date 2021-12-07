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
git clone --recursive -b adex_mod git@bbpgitlab.epfl.ch:hpc/sim/models/hippocampus.git
mkdir mod
cp hippocampus/mod/adex.mod mod
echo adex.mod > mod/neuron_only_mods.txt
build_neurodamus.sh mod

bb5_run ./x86_64/special -mpi -python $NEURODAMUS_PYTHON/init.py --configFile=$blueconfig --verbose
echo "/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-point/simulation/out.h5" > $outputdir/ref_spikes.txt
