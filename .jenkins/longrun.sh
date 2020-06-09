#!/bin/bash
[ $ENVUTILS_LOADED ] || source "${BASH_SOURCE%/*}/envutils.sh"
source "${BASH_SOURCE%/*}/../toolbox.sh"

BLUECONFIG_DIR=`pwd`
RUN_PY_TESTS="${RUN_PY_TESTS:-no}"
declare -A REF_RESULTS_LONGRUN
REF_RESULTS_LONGRUN["scx-v5-plasticity"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-scx-v5-plasticity/simulation-long"
REF_RESULTS_LONGRUN["hip-v6"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-hip-v6/simulation-long"
DATADIR="/gpfs/bbp.cscs.ch/data/scratch/proj12/bbprelman/cellular/"

run_long_test() (
    set -e
    testname=$1
    spec="$2"
    target=$3
    configfile="BlueConfig_longrun"
    resultdir=$DATADIR$testname
    outputdir=$resultdir"/output_longrun"
    if [ $RUN_PY_TESTS != "yes" ]; then
        outputdir=$outputdir"_hoc"
        configfile=$configfile"_hoc"
    else
        outputdir=$outputdir"_py"
        configfile=$configfile"_py"
    fi
    (set +x; log
     log "------------ LONG TEST: $testname ------------"
     log "spec: $spec"
     log "target: $target"
    )

    # prepare test
    cd $BLUECONFIG_DIR/$testname
    cp BlueConfig $configfile
    mkdir -p $outputdir
    blue_set OutputRoot $outputdir $configfile
    blue_set CircuitTarget $target $configfile
    blue_set Duration 100 $configfile
    cp $configfile $resultdir/
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
    date
    SALLOC_PARTITION="phase2_all" N=100 run_blueconfig $configfile
    date
    if [ $RUN_PY_TESTS = "no" ]; then
        REF_RESULTS_LONGRUN[$testname]=$resultdir"/output_longrun_py"
        test_check_results $outputdir "${REF_RESULTS_LONGRUN[$testname]}" "${REF_RESULTS_LONGRUN[$testname]}/out.sorted"
        cd $resultdir
        rm -rf output_longrun_hoc
        rm -rf output_longrun_py
    else
        sort -n -k'1,1' -k2 < $outputdir/out.dat | awk 'NR==1 { print; next } { printf "%.3f\t%d\n", $1, $2 }' > $outputdir/out.sorted
    fi
)
