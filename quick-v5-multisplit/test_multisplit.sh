#!/bin/sh
source ../toolbox.sh
configfile_bk $1

echo ">> Setting RunMode to LoadBalance in $blueconfig"
blue_set RunMode LoadBalance $blueconfig

# Clear eventual leftovers from previous run
rm -rf cx*

# Simulate with 8 ranks (Multisplit is still troublesome with ranks >> cells)
run_blueconfig $blueconfig
