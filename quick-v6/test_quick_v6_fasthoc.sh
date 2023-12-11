#!/bin/bash
source ../toolbox.sh
configfile_bk $1

rm -rf output #used for local testing

# Whenever we update simulation outputs driven by neuron changes
# _fasthoc folder must be regenerated with hocify from neurodamus-py
morpho_path=$(blue_get MorphologyPath $blueconfig)/_fasthoc_eigen_changes
blue_set MorphologyPath $morpho_path $blueconfig
blue_set MorphologyType hoc $blueconfig

metype_path=$(blue_get METypePath)
metype_path=${metype_path/\/hoc/\/fasthoc}
blue_set METypePath $metype_path $blueconfig

run_simulation $blueconfig

