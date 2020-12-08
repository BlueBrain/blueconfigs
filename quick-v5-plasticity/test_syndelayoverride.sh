#!/bin/bash
source ../toolbox.sh
configfile_bk $1
outputdir=${2:-output}

echo ">> Test AxonalDelay"

blue_set SynDelayOverride 1. $blueconfig "Connection ConL6Exc-Uni"
blue_set SynDelayOverride 2. $blueconfig "Connection ConInh-Uni"

run_blueconfig $blueconfig

# check against different reference spikes
echo "out.SynDelayOverride.sorted" > $outputdir/ref_spikes.txt
rm $outputdir/*.bbp
rm $outputdir/*.h5
