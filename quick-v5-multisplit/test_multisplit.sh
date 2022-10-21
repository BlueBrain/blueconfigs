#!/bin/sh
source ../toolbox.sh
configfile_bk $1

echo ">> Setting RunMode to LoadBalance in $blueconfig"
blue_set RunMode LoadBalance $blueconfig

# Clear eventual leftovers from previous run
rm -rf cx*

run_blueconfig $blueconfig
