#!/bin/bash
source ../toolbox.sh
configfile_bk $1

module list
# need to load unifurcation branch for the time being
spack install -y py-morphio@unifurcation
spack -d load py-morphio@unifurcation
module list


morpho_path=$(blue_get MorphologyPath $blueconfig)/h5
blue_set MorphologyPath $morpho_path $blueconfig
blue_set MorphologyType h5 $blueconfig

run_blueconfig $blueconfig
