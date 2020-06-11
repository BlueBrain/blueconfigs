#!/bin/bash

module load py-neurodamus
module list

source ../toolbox.sh
configfile_bk $1
outputdir=${2:-output}
newcircuit_path=/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-1k/touches/functional/newparams
blue_set nrnPath $newcircuit_path $blueconfig

echo ">> Test neurodamus-py set default synapse conductance_ratio from new circuit"
[ -d $outputdir ] || mkdir $outputdir
RUN_PY_TESTS=yes run_blueconfig $blueconfig |tee $outputdir/sim.log
if ! grep "update NMDA\|GABAB ratio" $outputdir/sim.log
then
    log_error "Should set NMDA or GABAB default ratio for this new circuit"
    exit -1
fi

echo ">> Test neurodamus-py scale synapse U parameter"
blue_set ExtracellularCalcium 1.25 $blueconfig
RUN_PY_TESTS=yes run_blueconfig $blueconfig | check_prints "Scale synapse U with u_hill and extra_cellular_calcium 1.25"

#skip result check
touch $outputdir/.exception.expected
