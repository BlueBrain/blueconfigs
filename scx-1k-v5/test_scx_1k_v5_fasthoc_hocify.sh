#!/bin/bash
set -e
module load py-neurodamus
module list

source ../toolbox.sh
configfile_bk $1

morpho_path=$(blue_get MorphologyPath $blueconfig)
cur_dir=`pwd`
fasthoc_path=$cur_dir/_fasthoc
rm -rf $fasthoc_path
hocify $morpho_path --output-dir=$fasthoc_path --verbose

blue_set MorphologyPath $fasthoc_path $blueconfig
blue_set MorphologyType hoc $blueconfig

run_simulation $blueconfig

