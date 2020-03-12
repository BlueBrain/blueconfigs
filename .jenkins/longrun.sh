#!/bin/bash
[ $ENVUTILS_LOADED ] || source "${BASH_SOURCE%/*}/envutils.sh"
source "${BASH_SOURCE%/*}/../toolbox.sh"

BLUECONFIG_DIR=`pwd`
RUN_PY_TESTS="${RUN_PY_TESTS:-no}"
declare -A REF_RESULTS_LONGRUN
REF_RESULTS_LONGRUN["scx-v5-plasticity"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-scx-v5-plasticity/simulation-long"
REF_RESULTS_LONGRUN["hip-v6"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-hip-v6/simulation-long"

run_long_test() (
    set -e
    testname=$1
    spec="$2"
    target=$3
    configfile="BlueConfig_longrun"
    outputdir="output_longrun"
    (set +x; log
     log "------------ LONG TEST: $testname ------------"
     log "spec: $spec"
     log "target: $target"
    )

    # prepare test
    cd $BLUECONFIG_DIR/$testname
    cp BlueConfig $configfile
    blue_set OutputRoot $outputdir $configfile
    blue_set CircuitTarget $target $configfile
    blue_set Duration 500 $configfile

    set +x
    log "Launching test $testname ($spec)"

    if [ "$DRY_RUN" ]; then
        return
    fi

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

    # run test
    SALLOC_PARTITION="prod" N=16 run_blueconfig $configfile
    test_check_results "output_longrun" "${REF_RESULTS_LONGRUN[$testname]}" "${REF_RESULTS_LONGRUN[$testname]}/out.sorted"

)
