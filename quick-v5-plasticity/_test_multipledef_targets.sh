#!/bin/bash
set -e
source ../toolbox.sh
configfile_bk BlueConfig
outputdir="${2:-output}"
blue_set OutputRoot "$outputdir" $blueconfig
blue_set TargetFile user.target.multipledef $blueconfig

export OMP_NUM_THREADS=1
run_blueconfig $blueconfig | tail -2 | grep -Pz '(?s)Error.  Multiple definitions for Target Mosaic.*\n.*Error.  Multiple definitions for Target Layer1'

mkdir -p "$outputdir"
touch "$outputdir/.exception.expected"

