#!/bin/bash
source ../toolbox.sh
configfile_bk $1

rm -rf output

morpho_path=$(blue_get MorphologyPath $blueconfig)/_fasthoc
blue_set MorphologyPath $morpho_path $blueconfig
blue_set MorphologyType hoc $blueconfig

metype_path=$(blue_get METypePath)
metype_path=${metype_path/\/hoc/\/fasthoc}
blue_set METypePath $metype_path $blueconfig

run_blueconfig $blueconfig

