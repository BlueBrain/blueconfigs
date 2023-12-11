#!/bin/sh
source ../toolbox.sh
echo $1
sonata_configfile_bk $1

sonataconf_set "target_simulator" "CORENEURON" "$sonataconfig"
echo "Run CORENEURON save with $sonataconfig"
n=1 run_simulation $sonataconfig --output-path=save --save=save/checkpoint

echo "Run CORENEURON restore with $sonataconfig"
n=1 run_simulation $sonataconfig --restore=save/checkpoint
#copy report from save folder for the result check as save has run the full duration
output_dir=$(less $sonataconfig |grep -o '"output_dir":\s*"[^"]*' | grep -o '[^"]*$')
cp save/*.h5 $output_dir/
