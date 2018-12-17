#!/bin/sh
source ../toolbox.sh

echo ">> Setting RunMode to LoadBalance in $1"
blue_set RunMode LoadBalance $1

# Clear eventual leftovers from previous run
rm -rf cx*

# Simulate with 8 ranks (Multisplit is still troublesome with ranks >> cells)
n=8 run_blueconfig $1
