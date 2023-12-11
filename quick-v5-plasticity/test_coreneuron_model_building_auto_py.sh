#!/bin/bash
set -e
module load py-neurodamus
module list

source ../toolbox.sh
configfile_bk $1
outdir=${2:-output}
blue_set OutputRoot "$outdir" $blueconfig
blue_set Simulator CORENEURON $blueconfig
blue_comment_section Report $blueconfig

export ND_DEBUG_CONN="62798"

export OMP_NUM_THREADS=1
RUN_PY_TESTS=yes run_simulation $blueconfig "--simulate-model=OFF"

RUN_PY_TESTS=yes run_simulation $blueconfig | tee ${outdir}/sim.log

grep 'SIMULATION (SKIP MODEL BUILD)' ${outdir}/sim.log
