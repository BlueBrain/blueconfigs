#!/bin/bash
set -e
source "${BASH_SOURCE%/*}/envutils.sh"

BLUECONFIG_DIR=`pwd`
# Test simulation results
OUTPUT=output

# list of simulation results
EXTENDED_RESULTS="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular"
declare -A REF_RESULTS
REF_RESULTS["scx-v5"]="$EXTENDED_RESULTS/circuit-scx-v5/simulation"
REF_RESULTS["scx-v6"]="$EXTENDED_RESULTS/circuit-scx-v6/simulation"
REF_RESULTS["scx-1k-v5"]="$EXTENDED_RESULTS/circuit-1k/simulation"
REF_RESULTS["scx-2k-v6"]="$EXTENDED_RESULTS/circuit-2k/simulation"
REF_RESULTS["scx-v5-gapjunctions"]="$EXTENDED_RESULTS/circuit-scx-v5-gapjunctions/simulation"
REF_RESULTS["scx-v5-bonus-minis"]="$EXTENDED_RESULTS/circuit-scx-v5-bonus-minis/simulation"
REF_RESULTS["scx-v5-plasticity"]="$EXTENDED_RESULTS/circuit-scx-v5-plasticity/simulation"
REF_RESULTS["hip-v6"]="$EXTENDED_RESULTS/circuit-hip-v6/simulation"


_prepare_run() {
    testname=$1
    neurodamus_version=$2
    echo -e "\n[$Blue INFO $ColorReset] Running test $testname ($neurodamus_version)"
    echo -e "[$Blue INFO $ColorReset] ------------------"

    # load required modules
    echo "COMMANDS: module purge; spack load $neurodamus_version"
    module purge
    spack load $neurodamus_version
    module list

    # cd to corresponding directory and clean output
    echo "COMMANDS: cd $BLUECONFIG_DIR/$testname; rm -rf $OUTPUT && mkdir -p $OUTPUT"
    cd $BLUECONFIG_DIR/$testname
    rm -rf $OUTPUT && mkdir -p $OUTPUT
}


run_debug() {
    _prepare_run $1 $2
    N=2 bb5_run special $HOC_LIBRARY_PATH/_debug.hoc -mpi

    # compare nrndat
    for nrnfile in *.nrndat; do
        (set -x
         diff -wy --suppress-common-lines expected_nrndat/$nrnfile $nrnfile)
    done
}


test_check_results() {
    testname=$1

    # sort the spikes and compare the output
    [ -f $OUTPUT/spikes.dat ] && mv $OUTPUT/spikes.dat $OUTPUT/out.dat
    sort -n -k'1,1' -k2 < $OUTPUT/out.dat > $OUTPUT/out.sorted
    diff -wy --suppress-common-lines out.sorted $OUTPUT/out.sorted

    # compare reports
    for report in $(cd $OUTPUT && ls *.bbp); do
        (set -x
         cmp ${REF_RESULTS[$testname]}/$report $OUTPUT/$report)
    done

    echo -e "[$Green PASS $ColorReset] Test $testname successfull"
}


run_test() {
    testname=$1
    _prepare_run $1 $2
    N=2 bb5_run special $HOC_LIBRARY_PATH/init.hoc -mpi

    test_check_results $testname
}
