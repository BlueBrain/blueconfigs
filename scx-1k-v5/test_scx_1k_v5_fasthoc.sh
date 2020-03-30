#!/bin/bash
source ../toolbox.sh
configfile_bk $1

rm -rf output

morpho_path=$(blue_get MorphologyPath $blueconfig)/_fasthoc
blue_set MorphologyPath $morpho_path $blueconfig
blue_set MorphologyType hoc $blueconfig

run_blueconfig $blueconfig

