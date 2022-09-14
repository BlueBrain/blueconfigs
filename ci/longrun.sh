#!/bin/bash
[ $ENVUTILS_LOADED ] || source "${BASH_SOURCE%/*}/envutils.sh"
source "${BASH_SOURCE%/*}/../toolbox.sh"

BLUECONFIG_DIR=`pwd`
RUN_PY_TESTS="${RUN_PY_TESTS:-no}"
declare -A REF_RESULTS_LONGRUN
REF_RESULTS_LONGRUN["scx-v5-plasticity"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-scx-v5-plasticity/simulation-long"
REF_RESULTS_LONGRUN["quick-hip-multipopulation"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-hip-mooc/simulation-long"
REF_RESULTS_LONGRUN["mousify"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-mousify/simulation-long"
REF_RESULTS_LONGRUN["thalamus"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-thalamus/simulation-long"

run_long_test() (
    set -e
    testname=$1
    spec="$2"
    target="$3"
    configfile="BlueConfig_longrun"
    outputdir="output_longrun"
    (set +x; log
     log "------------ LONG TEST: $testname ------------"
     log "spec: $spec"
     log "target: $target"
    )

    # prepare test
    cd "$BLUECONFIG_DIR/$testname"
    cp BlueConfig "$configfile"
    blue_set OutputRoot "$outputdir" "$configfile"
    blue_set CircuitTarget "$target" "$configfile"
    blue_set Duration 500 "$configfile"
    blue_set RunMode WholeCell "$configfile"
    blue_set Dt 5 "$configfile" 'Report'  # No need for very dense reports

    # Coreneuron long run
    if [ $testname = "quick-hip-multipopulation" ]; then
        blue_set Simulator CORENEURON "$configfile"
        blue_set SpontMinis 0.01 "$configfile" 'Connection SC-All'
        blue_uncomment_section 'Report soma' "$configfile"
    fi

    set +x
    head -n 40 "$configfile"

    log "Launching test $testname ($spec)"

    # If neurodamus spec not given, check loaded
    if [ -z "$spec" ]; then
        spec=default
        which special # Ensure available
    else
        echo "COMMANDS: module purge; spack load $spec" "DBG"
        module purge
        if [ $RUN_PY_TESTS = "yes" ]; then
            echo "Loading python with deps"
            module load py-neurodamus
        fi
        spack load $spec
    fi
    module list
    module list -t 2>&1 | grep neurodamus | while read mod; do module show "$mod"; done
    module load unstable py-bluepy  # req. for the libsonata readers

    nodes=64
    if [ $testname = "thalamus" ]; then
        nodes=16  # thalamus cell count is slightly lower and mods are really fast
    fi
    SALLOC_PARTITION=prod N=${nodes} n=$(expr "$nodes" '*' 40) run_blueconfig "$configfile"
    test_check_results "$outputdir" "${REF_RESULTS_LONGRUN[$testname]}" "${REF_RESULTS_LONGRUN[$testname]}/out.sorted" 0.1

)
