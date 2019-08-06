#!/bin/bash
set -e
source ../toolbox.sh
configfile_bk BlueConfig.manyreplay
outdir=${2:-output}
blue_set OutputRoot "$outdir" $blueconfig

export OMP_NUM_THREADS=1
run_blueconfig $blueconfig

