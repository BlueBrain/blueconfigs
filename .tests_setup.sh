#!/bin/bash
source ci/envutils.sh
source ./toolbox.sh

# temp fix while neurodamus requires coreneuron master after a br change
# In normal conditions take the latest deployed version
#export CORENEURON_BRANCH=${CORENEURON_BRANCH:-"master"}
#export NEURON_BRANCH=${NEURON_BRANCH:-"master"}

# Test parameters eventually defined by Jenkins (env vars)
set +x
export WORKSPACE=${WORKSPACE:-"`pwd`"}
export TEST_VERSIONS=${TEST_VERSIONS:-"neocortex ncx_bare ncx_plasticity hippocampus thalamus mousify ncx_ngv"}
export SPACK_BRANCH=${SPACK_BRANCH:-""}
export RUN_PY_TESTS=${RUN_PY_TESTS:-"no"}
export DRY_RUN=${DRY_RUN:-""}  # Dont actually run sims. Default is false
log "WORKSPACE=$WORKSPACE; TEST_VERSIONS=$TEST_VERSIONS; SPACK_BRANCH=$SPACK_BRANCH; RUN_PY_TESTS=$RUN_PY_TESTS" "DBG"

# Test definitions
BUILD_COMPILER="oneapi" # also used when constructing reference file paths
BUILD_TYPE="FastDebug" # also used when constructing reference file paths
BUILD_VERSION="@develop%${BUILD_COMPILER}"
DATADIR="/gpfs/bbp.cscs.ch/project/proj12/jenkins"
EXTRA_VARIANT="$ND_VARIANT"
# dropped support for overriding BUILD_OPTIONS as it makes BUILD_TYPE handling harder and it seemed not to be used
BUILD_OPTIONS="^neuron+coreneuron build_type=${BUILD_TYPE}"
DEFAULT_VARIANT="+coreneuron"
CORENRN_DEP=""
NEURODAMUS_PY_VERSION="py-neurodamus@develop"
_BASE_OPTIONS="$DEFAULT_VARIANT$EXTRA_VARIANT $CORENRN_DEP"

log "DATADIR=$DATADIR; BASE_OPTIONS=$_BASE_OPTIONS; BUILD_OPTIONS=$BUILD_OPTIONS" DBG

declare -A VERSIONS
# Master is a plain v5+v6 version
VERSIONS[neocortex]="neurodamus-neocortex$BUILD_VERSION ~plasticity$_BASE_OPTIONS"
VERSIONS[ncx_bare]="neurodamus-neocortex$BUILD_VERSION ~plasticity~coreneuron~synapsetool$EXTRA_VARIANT"
VERSIONS[ncx_plasticity]="neurodamus-neocortex$BUILD_VERSION +plasticity$_BASE_OPTIONS"
VERSIONS[hippocampus]="neurodamus-hippocampus$BUILD_VERSION $_BASE_OPTIONS"
VERSIONS[thalamus]="neurodamus-thalamus$BUILD_VERSION $_BASE_OPTIONS"
VERSIONS[mousify]="neurodamus-mousify$BUILD_VERSION $_BASE_OPTIONS"
VERSIONS[ncx_ngv]="neurodamus-neocortex$BUILD_VERSION +ngv+metabolism+synapsetool~plasticity~coreneuron"

# list of simulations to run
declare -A TESTS
TESTS[neocortex]="sonataconf-scx-v5-uhill-conductance-scale sonataconf-quick-scx-multi-circuit sonataconf-sscx-O1 sonataconf-quick-sscx-O1"
TESTS[ncx_bare]="quick-v5-gaps quick-v6 quick-v5-multisplit"
TESTS[ncx_plasticity]="sonataconf-sscx-v7-plasticity sonataconf-quick-v5-plasticity"
TESTS[hippocampus]="sonataconf-quick-hip-multipopulation sonataconf-hippocampus"
TESTS[thalamus]="sonataconf-quick-thalamus sonataconf-thalamus"
TESTS[mousify]="sonataconf-quick-mousify"
TESTS[ncx_ngv]="sonataconf-quick-multiscale"

# Prepare spack (install+env)
source ci/spack_setup.sh || return $?

# Routines for installing
source ci/build.sh || return $?

# load test/check routines
source ci/testutils.sh

