source ../toolbox.sh
outputdir="${2:-output}"
configfile_bk $1

# We require neurodamus-py
if [ "$RUN_PY_TESTS" != "yes" ]; then
    echo "Skipping test: Neurodamus-py only"
    mkdir -p "$outputdir"
    touch "$outputdir/.exception.expected"
    return 0
fi
blue_comment_section Report $blueconfig
blue_set CircuitTarget mini420 $blueconfig
blue_set SYNAPSES__init_depleted 1 $blueconfig Conditions
run_blueconfig $blueconfig

# Let the framework check against different reference spikes
echo "out.initdepleted.sorted" > $outputdir/ref_spikes.txt
