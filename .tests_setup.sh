#!/bin/bash
source .jenkins/envutils.sh

# Test parameters eventually defined by Jenkins (env vars)
export WORKSPACE=${WORKSPACE:-"`pwd`"}
export TEST_VERSIONS=${TEST_VERSIONS:-"neocortex ncx_bare ncx_plasticity hippocampus thalamus"}
export SPACK_BRANCH=${SPACK_BRANCH:-"develop"}
export RUN_PY_TESTS=${RUN_PY_TESTS:-"no"}

# Test definitions
DATADIR="/gpfs/bbp.cscs.ch/project/proj12/jenkins"
if [ $RUN_PY_TESTS = "yes" ]; then EXTRA_VARIANT="$ND_VARIANT+python"; fi
BUILD_OPTIONS="${BUILD_OPTIONS:-"^neuron+cross-compile+debug %intel"}"
DEFAULT_VARIANT="~plasticity+coreneuron+synapsetool"
CORENRN_DEP="^coreneuron+debug"

declare -A VERSIONS
# Master is a plain v5+v6 version
VERSIONS[neocortex]="neurodamus-neocortex@develop$DEFAULT_VARIANT$EXTRA_VARIANT $CORENRN_DEP"
VERSIONS[ncx_bare]="neurodamus-neocortex@develop~plasticity~coreneuron~synapsetool$EXTRA_VARIANT"
VERSIONS[ncx_plasticity]="neurodamus-neocortex@develop+plasticity+coreneuron+synapsetool$EXTRA_VARIANT $CORENRN_DEP"
VERSIONS[hippocampus]="neurodamus-hippocampus@develop$EXTRA_VARIANT"
VERSIONS[thalamus]="neurodamus-thalamus@develop$EXTRA_VARIANT"

# list of simulations to run
declare -A TESTS
TESTS[neocortex]="scx-v5 scx-v6 scx-1k-v5 scx-2k-v6 scx-v5-gapjunctions scx-v5-bonus-minis"
TESTS[ncx_bare]="quick-v5-gaps quick-v6 quick-v5-multisplit"
TESTS[ncx_plasticity]="scx-v5-plasticity"
TESTS[hippocampus]="hip-v6"
TESTS[thalamus]="thalamus"


# Prepare spack
# =============
export SPACK_INSTALL_PREFIX="${SPACK_INSTALL_PREFIX:-${WORKSPACE}/INSTALL_HOME}"
export SOFTS_DIR_PATH=$SPACK_INSTALL_PREFIX  # Deprecated, but might still be reqd

if [[ -z "$USE_SYSTEM_SPACK" || -z "$SPACK_ROOT" ]]; then
    BUILD_HOME="${WORKSPACE}/BUILD_HOME"
    export SPACK_ROOT="${BUILD_HOME}/spack"
    source .jenkins/spack_setup.sh
    # Temporarily required since latest large patches
    export MODULEPATH=$SPACK_INSTALL_PREFIX/modules/tcl/linux-rhel7-x86_64:$MODULEPATH
fi

# load test/check routines
source .jenkins/testutils.sh


# HELPERS
# =======

install_neurodamus() (
    source .jenkins/build.sh
)


run_all_tests() (
    set -e
    unset spec
    which special || LOAD_SPEC=1
    for version in $TEST_VERSIONS; do
        [ $LOAD_SPEC ] && spec=${VERSIONS[$version]}
        for testname in ${TESTS[$version]}; do
            run_test $testname $spec
        done
    done
)


run_quick_tests() (
    _VERSIONS_BK=$TEST_VERSIONS
    _TESTS_NCX=${TESTS[neocortex]}
    TEST_VERSIONS="ncx_bare neocortex"
    TESTS[neocortex]=${TESTS[ncx_bare]}

    run_all_tests

    TEST_VERSIONS=$_VERSIONS_BK
    TESTS[neocortex]=_TESTS_NCX
)
