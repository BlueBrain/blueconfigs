#!/bin/bash
set -e
source ../toolbox.sh
configfile_bk BlueConfig.manyreplay
outdir=${2:-output}
blue_set OutputRoot "$outdir" $blueconfig
blue_comment_section Report $blueconfig
blue_uncomment_section "Report compartment_SONATA" $blueconfig

export OMP_NUM_THREADS=1
run_simulation $blueconfig

