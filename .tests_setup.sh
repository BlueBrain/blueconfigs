#!/bin/bash
source .jenkins/envutils.sh

# Test parameters eventually defined by Jenkins (env vars)
export WORKSPACE=${WORKSPACE:-"`pwd`"}
export TEST_VERSIONS=${TEST_VERSIONS:-"master master_no_syn2 hippocampus plasticity"}
export SPACK_BRANCH=${SPACK_BRANCH:-"develop"}
export RUN_PY_TESTS=${RUN_PY_TESTS:-"no"}

# Test definitions
DATADIR="/gpfs/bbp.cscs.ch/project/proj12/jenkins"
if [ $RUN_PY_TESTS = "yes" ]; then EXTRA_VARIANT="$EXTRA_VARIANT+python"; fi
DEFAULT_VARIANT="${DEFAULT_VARIANT:-"~coreneuron+syntool"}$EXTRA_VARIANT %intel"
BUILD_OPTIONS="${BUILD_OPTIONS:-"^neuron+cross-compile+debug %intel"}"

declare -A VERSIONS
VERSIONS[master]="neurodamus@master$DEFAULT_VARIANT"
VERSIONS[master_no_syn2]="neurodamus@master~coreneuron~syntool$EXTRA_VARIANT"
VERSIONS[hippocampus]="neurodamus@hippocampus$DEFAULT_VARIANT"
VERSIONS[plasticity]="neurodamus@plasticity+coreneuron+syntool$EXTRA_VARIANT ^coreneuron+debug%intel"
VERSIONS[master_quick]=${VERSIONS[master]}

# list of simulations to run
# NOTE: scx-v5-gapjunctions is re-run without syn2 support since it's a very complete test
declare -A TESTS
TESTS[master]="scx-v5 scx-v6 scx-1k-v5 scx-2k-v6 scx-v5-gapjunctions scx-v5-bonus-minis quick-v5-multisplit"
TESTS[master_no_syn2]="scx-v5-gapjunctions"
TESTS[master_quick]="quick-v5-gaps quick-v6 quick-v5-multisplit"
TESTS[hippocampus]="hip-v6"
TESTS[plasticity]="scx-v5-plasticity"


## Prepare spack
if [[ -z "$USE_SYSTEM_SPACK" || -z "$SPACK_ROOT" ]]; then
    BUILD_HOME="${WORKSPACE}/BUILD_HOME"
    export SOFTS_DIR_PATH="${WORKSPACE}/INSTALL_HOME"
    export SPACK_ROOT="${BUILD_HOME}/spack"
    source .jenkins/spack_setup.sh
fi

# load test/check routines
source .jenkins/testutils.sh


# ------------------------
# HELPERS
# ------------------------
install_neurodamus() {
    source .jenkins/build.sh
}


run_all_tests() {
    for version in $TEST_VERSIONS; do
        spec=${VERSIONS[$version]}
        for testname in ${TESTS[$version]}; do
            run_test $testname $spec
        done
    done
}


run_quick_tests() {
    _TESTS_BK=$TEST_VERSIONS
    TEST_VERSIONS="master_quick"
    run_all_tests
    TEST_VERSIONS=$_TESTS_BK
}
