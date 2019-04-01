#!/bin/bash
set -e
source ../toolbox.sh
configfile_bk $1

blue_set ProspectiveHosts $(( 2 * 2 * 36 )) $blueconfig  # $ 2 loops with 2 nodes
blue_set Simulator CORENEURON $blueconfig
blue_comment "Report soma" $blueconfig
head -n30 $blueconfig

export OMP_NUM_THREADS=1

run_blueconfig $blueconfig

