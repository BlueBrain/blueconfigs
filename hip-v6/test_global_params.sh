#!/bin/bash
source ../toolbox.sh
configfile_bk $1
outputdir="${2:-output}"

# We require neurodamus-py
if [ "$RUN_PY_TESTS" != "yes" ]; then
    echo "Skipping test: Neurodamus-py only"
    mkdir -p "$outputdir"
    touch "$outputdir/.exception.expected"
    return 1
fi

#General changes
blue_comment_section Report $blueconfig
blue_set CircuitTarget mini420 $blueconfig
blue_set Duration 40 $blueconfig

echo ">> Test GABA rise time randomize off"
cp $blueconfig "$blueconfig"_p1
blue_set RandomizeGabaRiseTime False "$blueconfig"_p1
run_blueconfig "$blueconfig"_p1
check_spike_files $outputdir/out.dat out.GABARisetime.sorted

echo ">> Test GABA rise time randomize off from Conditions block"
cp $blueconfig "$blueconfig"_p2
blue_set randomize_Gaba_risetime False "$blueconfig"_p2 Conditions
run_blueconfig "$blueconfig"_p2

# Let the framework check against different reference spikes
echo "out.GABARisetime.sorted" > $outputdir/ref_spikes.txt
