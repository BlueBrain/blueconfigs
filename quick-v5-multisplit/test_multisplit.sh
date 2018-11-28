#!/bin/sh
source ../toolbox.sh

blue_set RunMode LoadBalance $1

# Multisplit is still troublesome with ranks >> cells
n=8 run_blueconfig $1

