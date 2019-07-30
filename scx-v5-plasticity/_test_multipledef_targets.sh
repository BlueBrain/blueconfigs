#!/bin/bash
set -e
source ../toolbox.sh
configfile_bk BlueConfig
outdir=${2:-output}
blue_set OutputRoot "$outdir" $blueconfig
blue_set TargetFile user.target.multipledef $blueconfig

export OMP_NUM_THREADS=1
run_blueconfig $blueconfig

touch .exception.expected

