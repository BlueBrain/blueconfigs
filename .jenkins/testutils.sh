#!/bin/bash
set -e
[ $ENVUTILS_LOADED ] || source "${BASH_SOURCE%/*}/envutils.sh"
BLUECONFIG_DIR=`pwd`

# defaults
RUN_PY_TESTS="${RUN_PY_TESTS:-master}"
DATADIR="${DATADIR:-/gpfs/bbp.cscs.ch/project/proj12/jenkins}"

# list of simulation results
EXTENDED_RESULTS="$DATADIR/cellular"
declare -A REF_RESULTS
REF_RESULTS["scx-v5"]="$EXTENDED_RESULTS/circuit-scx-v5/simulation"
REF_RESULTS["scx-v6"]="$EXTENDED_RESULTS/circuit-scx-v6/simulation"
REF_RESULTS["scx-1k-v5"]="$EXTENDED_RESULTS/circuit-1k/simulation"
REF_RESULTS["scx-2k-v6"]="$EXTENDED_RESULTS/circuit-2k/simulation"
REF_RESULTS["scx-v5-gapjunctions"]="$EXTENDED_RESULTS/circuit-scx-v5-gapjunctions/simulation"
REF_RESULTS["scx-v5-bonus-minis"]="$EXTENDED_RESULTS/circuit-scx-v5-bonus-minis/simulation"
REF_RESULTS["scx-v5-plasticity"]="$EXTENDED_RESULTS/circuit-scx-v5-plasticity/simulation"
REF_RESULTS["hip-v6"]="$EXTENDED_RESULTS/circuit-hip-v6/simulation"
REF_RESULTS["quick-v5-gaps"]="$EXTENDED_RESULTS/circuit-scx-v5-gapjunctions/simulation_quick"
REF_RESULTS["quick-v6"]="$EXTENDED_RESULTS/circuit-2k/simulation_quick"



_prepare_test() {
    _set=$-
    set -e
    unset localtest

    # If test not provided check if curdir has BlueConfig
    if [ -z "$testname" ]; then
        if [[ -f BlueConfig && -f out.sorted ]]; then
            testname="${PWD##*/}"
            localtest=1
        else
            echo "Test name not provided and not found in cur dir"
            exit -1
        fi
    fi

    # If neurodamus spec not given, check cur loaded
    if [ -z "$spec" ]; then
        spec=default
        which special  # Ensure available
    fi

    # To run in parallel output and BlueConfig must be unique
    hash=$(echo $spec | md5sum | cut -c 1-8)
    output="output_$hash"
    blueconfig="BlueConfig_$hash"

    #
    # Now actually load env modules, patch BlueConfig and clear any results
    set +x
    echo -e "\n[$Blue INFO $ColorReset] Running test $testname ($spec) #$hash"
    echo -e "[$Blue INFO $ColorReset] ------------------"

    # load required modules
    if [ $spec != "default" ]; then
        echo "COMMANDS: module purge; spack load $spec"
        module purge
        if [ $RUN_PY_TESTS = "yes" ]; then spack load python; fi
        spack load $spec
    fi
    module list
    module list -t 2>&1 | grep neurodamus | while read mod; do module show "$mod"; done

    set -x
    [ "$localtest" ] || cd $BLUECONFIG_DIR/$testname
    cp BlueConfig $blueconfig
    sed -i "s#OutputRoot.*#OutputRoot $output#" $blueconfig

    rm -rf $output && mkdir -p $output
    set +x && set -$_set  # restore env
}


run_debug() (
    testname=$1
    spec=$2
    _prepare_test

    bb5_run special $HOC_LIBRARY_PATH/_debug.hoc -mpi

    # compare nrndat
    for nrnfile in *.nrndat; do
        (set -x
         diff -wy --suppress-common-lines expected_nrndat/$nrnfile $nrnfile)
    done
)


test_check_results() {
    # sort the spikes and compare the output
    [ -f $output/spikes.dat ] && mv $output/spikes.dat $output/out.dat
    sort -n -k'1,1' -k2 < $output/out.dat > $output/out.sorted
    (set -x; diff -wy --suppress-common-lines out.sorted $output/out.sorted)

    # compare reports
    set +x
    for report in $(cd $output && ls *.bbp); do
        (set -x
         cmp ${REF_RESULTS[$testname]}/$report $output/$report)
    done

    echo -e "[$Green PASS $ColorReset] Test $testname successfull\n"
    set -$_set  # restore
}


run_test() (
    testname=$1
    spec=$2
    _prepare_test

    if [[ $RUN_PY_TESTS == "yes" && $NEURODAMUS_PYTHON ]]; then
        INIT_ARGS=("-python" "$NEURODAMUS_PYTHON/init.py" "--configFile=BlueConfig_$hash")
    else
        INIT_ARGS=("-c" "{strdef configFile configFile=\"BlueConfig_$hash\"}" "$HOC_LIBRARY_PATH/init.hoc")
    fi

    N=$(set -x; [[ $testname =~ quick* ]] && echo 1 || echo 2) \
    bb5_run special "${INIT_ARGS[@]}" -mpi

    test_check_results
    set +e
)


# Prepare for immediate test run
_set=$-; set +x
source $SPACK_ROOT/share/spack/setup-env.sh
set -$_set
set +e
