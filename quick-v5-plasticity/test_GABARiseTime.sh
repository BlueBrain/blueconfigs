#!/bin/bash
source ../toolbox.sh
configfile_bk $1
outputdir=${2:-output}

echo ">> Test GABA rise time randomize off"

blue_comment_section Report $blueconfig
blue_set RandomizeGabaRiseTime False $blueconfig
run_blueconfig $blueconfig

check_spike_files $outputdir/out.dat out.GABARisetime.sorted

echo ">> Test GABA rise time randomize off from Conditions block"
module load py-neurodamus
configfile_bk $1
blue_comment_section Report $blueconfig
blue_set randomize_Gaba_risetime False $blueconfig Conditions
RUN_PY_TESTS=yes run_blueconfig $blueconfig

# Let the framework check against different reference spikes
echo "out.GABARisetime.sorted" > $outputdir/ref_spikes.txt
