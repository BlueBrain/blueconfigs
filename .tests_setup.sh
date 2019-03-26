#!/bin/bash
source .jenkins/envutils.sh

# Test parameters eventually defined by Jenkins (env vars)
export WORKSPACE=${WORKSPACE:-"`pwd`"}
export TEST_VERSIONS=${TEST_VERSIONS:-"master plasticity master_sympy plasticity_sympy mousify_sympy"}
export SPACK_BRANCH=${SPACK_BRANCH:-"develop"}
export RUN_PY_TESTS=${RUN_PY_TESTS:-"no"}

# Test definitions
DATADIR="/gpfs/bbp.cscs.ch/project/proj12/jenkins"
BUILD_OPTIONS="${BUILD_OPTIONS:-"^neuron+cross-compile+debug %intel "}"

declare -A VERSIONS
VERSIONS[master]="neurodamus@master+coreneuron^coreneuron+nmodl~sympy+debug"
VERSIONS[hippocampus]="neurodamus@hippocampus+coreneuron^coreneuron+nmodl~sympy+debug"
VERSIONS[plasticity]="neurodamus@plasticity+coreneuron^coreneuron+nmodl~sympy+debug"
VERSIONS[master_sympy]="neurodamus@master+coreneuron^coreneuron+nmodl+sympy+debug"
VERSIONS[hippocampus_sympy]="neurodamus@hippocampus+coreneuron^coreneuron+nmodl+sympy+debug"
VERSIONS[plasticity_sympy]="neurodamus@plasticity+coreneuron^coreneuron+nmodl+sympy+debug"
VERSIONS[mousify_sympy]="neurodamus@mousify+coreneuron^coreneuron+nmodl+sympy+debug"

# list of simulations to run
# NOTE: scx-v5-gapjunctions is re-run without syn2 support since it's a very complete test
declare -A TESTS
TESTS[master]="scx-v5 scx-2k-v6 scx-v5-bonus-minis"
TESTS[plasticity]="scx-v5-plasticity"
TESTS[master_sympy]="scx-v5 scx-2k-v6 scx-v5-bonus-minis"
TESTS[plasticity_sympy]="scx-v5-plasticity"
TESTS[mousify_sympy]="mousify"


# Prepare spack
# =============
export SOFTS_DIR_PATH="${WORKSPACE}/INSTALL_HOME"
export SPACK_INSTALL_PREFIX="$SOFTS_DIR_PATH"

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

install_neurodamus() {
    source .jenkins/build.sh
}


run_all_tests() (
    set +e  # Continue on errors
    for version in $TEST_VERSIONS; do
        spec=${VERSIONS[$version]}
        for testname in ${TESTS[$version]}; do
            echo "Patching for no reports"
            sed -i 's/Report/#Report/' $testname/BlueConfig
            run_test $testname $spec
        done
    done
)

