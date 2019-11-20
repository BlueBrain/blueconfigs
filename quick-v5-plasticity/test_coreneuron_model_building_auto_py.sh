#!/bin/bash
set -e
module list

source ../toolbox.sh
configfile_bk $1
outdir=${2:-output}
blue_set OutputRoot "$outdir" $blueconfig
blue_set Simulator CORENEURON $blueconfig

export OMP_NUM_THREADS=1
RUN_PY_TESTS=yes run_blueconfig $blueconfig "--simulate-model=OFF"

RUN_PY_TESTS=yes run_blueconfig $blueconfig | tee ${outdir}/sim.log

grep 'SIMULATION (SKIP MODEL BUILD)' ${outdir}/sim.log
