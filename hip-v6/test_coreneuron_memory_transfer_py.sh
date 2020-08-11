#!/bin/bash
set -e
module load py-neurodamus
module list

source ../toolbox.sh
configfile_bk $1
outdir=${2:-output}
blue_set OutputRoot "$outdir" $blueconfig
blue_set Simulator CORENEURON $blueconfig

export OMP_NUM_THREADS=1
RUN_PY_TESTS=yes run_blueconfig $blueconfig "--memory-transfer"
