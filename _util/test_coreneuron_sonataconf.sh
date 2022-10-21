#!/bin/sh
source ../toolbox.sh
echo $1
sonata_configfile_bk $1

sonataconf_set "target_simulator" "CORENEURON" "$sonataconfig"
echo "Run CORENEURON with $sonataconfig"
run_blueconfig $sonataconfig
