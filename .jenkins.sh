#!/bin/bash
set -ex
source .jenkins/envutils.sh

# Parameters eventually defined in Jenkins
export WORKSPACE=${WORKSPACE:-"`pwd`"}
export TEST_VERSIONS=${TEST_VERSIONS:-"master master_no_syn2 hippocampus plasticity"}
export SPACK_BRANCH=${SPACK_BRANCH:-"develop"}
export RUN_PY_TESTS=${RUN_PY_TESTS:-"no"}

# Definitions
export DATADIR="/gpfs/bbp.cscs.ch/project/proj12/jenkins"
export HOME="${WORKSPACE}/BUILD_HOME"
export SOFTS_DIR_PATH="${WORKSPACE}/INSTALL_HOME"
export SPACK_ROOT="${HOME}/spack"
export PATH="${SPACK_ROOT}/bin:${PATH}"

DEFAULT_VARIANT="~coreneuron+syntool+python"
BUILD_OPTIONS="%intel ^neuron+cross-compile+debug %intel"

declare -A VERSIONS
VERSIONS[master]="neurodamus@master$DEFAULT_VARIANT"
VERSIONS[master_no_syn2]="neurodamus@master~coreneuron~syntool+python"
VERSIONS[hippocampus]="neurodamus@hippocampus$DEFAULT_VARIANT"
VERSIONS[plasticity]="neurodamus@plasticity+coreneuron~syntool+python"

# list of simulations to run
# NOTE: scx-v5-gapjunctions is re-run without syn2 support since it's a very complete
#       test, loading synapses, projections and GJs, some with syn2 and nrn, other only nrn
declare -A TESTS
TESTS[master]="scx-v5 scx-v6 scx-1k-v5 scx-2k-v6 scx-v5-gapjunctions scx-v5-bonus-minis"
TESTS[master_no_syn2]="scx-v5-gapjunctions"
TESTS[hippocampus]="hip-v6"
TESTS[plasticity]="scx-v5-plasticity"


## Prepare env
source .jenkins/envsetup.sh

# Build req versions
source .jenkins/build.sh

# load test/check routines
source .jenkins/testutils.sh

# iterate over all test
for version in $TEST_VERSIONS; do
    spec=${VERSIONS[$version]}
    for testname in ${TESTS[$version]}; do
        run_test $testname $spec
    done
done

echo -e "[$Green SUCCESS $ColorReset] ALL TESTS PASSED"
