#!/bin/bash
source ../toolbox.sh
configfile_bk $1
outputdir=${2:-output}

echo ">> Test GABA rise time randomize off"

blue_set RandomizeGabaRiseTime False $blueconfig
run_blueconfig $blueconfig 

# check against different reference spikes
echo "out.GABARisetime.sorted" > $outputdir/ref_spikes.txt
rm $outputdir/*.bbp
rm $outputdir/*.h5
