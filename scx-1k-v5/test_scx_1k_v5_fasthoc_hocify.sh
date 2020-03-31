#!/bin/bash
set -e
module load py-neurodamus
module list

#temoprarily need to load neuron@develop for NEURON_NFRAME and commands access
spack install -y neuron@develop%intel@19.0.4
spack load neuron@develop%intel@19.0.4
module list
nrngui --version

source ../toolbox.sh
configfile_bk $1

morpho_path=$(blue_get MorphologyPath $blueconfig)
cur_dir=`pwd`
fasthoc_path=$cur_dir/_fasthoc
rm -rf $fasthoc_path
hocify $morpho_path --output-dir=$fasthoc_path --verbose

blue_set MorphologyPath $fasthoc_path $blueconfig
blue_set MorphologyType hoc $blueconfig

run_blueconfig $blueconfig


