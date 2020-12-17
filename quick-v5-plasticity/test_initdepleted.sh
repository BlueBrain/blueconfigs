#!bin/bash
source ../toolbox.sh
configfile_bk $1
outputdir=${2:-output}

echo ">> Test to initialize synapses in depleted state"
blue_comment_section Report $blueconfig
blue_set SYNAPSES__init_depleted 1 $blueconfig Conditions
RUN_PY_TESTS=yes run_blueconfig $blueconfig

# Let the framework check against different reference spikes
echo "out.initdepleted.sorted" > $outputdir/ref_spikes.txt
