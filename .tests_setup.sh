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
export TEST_VERSIONS=${TEST_VERSIONS:-"neocortex ncx_bare ncx_plasticity hippocampus thalamus mousify"}
export SPACK_BRANCH=${SPACK_BRANCH:-""}
export RUN_PY_TESTS=${RUN_PY_TESTS:-"no"}
export DRY_RUN=${DRY_RUN:-""}  # Dont actually run sims. Default is false
log "WORKSPACE=$WORKSPACE; TEST_VERSIONS=$TEST_VERSIONS; SPACK_BRANCH=$SPACK_BRANCH; RUN_PY_TESTS=$RUN_PY_TESTS" "DBG"

# Test definitions
BUILD_VERSION="@develop%intel"
DATADIR="/gpfs/bbp.cscs.ch/project/proj12/jenkins"
EXTRA_VARIANT="$ND_VARIANT"
BUILD_OPTIONS="${BUILD_OPTIONS:-"^neuron+debug"}"
DEFAULT_VARIANT="+coreneuron+synapsetool"
CORENRN_DEP="^coreneuron build_type=Debug"
NEURODAMUS_PY_VERSION="py-neurodamus+all_deps @develop"
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

# list of simulations to run
declare -A TESTS
TESTS[neocortex]="scx-v5 scx-v6 scx-1k-v5 scx-1k-v5-newparams scx-2k-v6 scx-v5-gapjunctions scx-v5-bonus-minis quick-1k-v5-nodesets quick-scx-multi-circuit"
TESTS[ncx_bare]="quick-v5-gaps quick-v6 quick-v5-multisplit point-neuron"
TESTS[ncx_plasticity]="scx-v5-plasticity quick-v5-plasticity sscx-v7-plasticity quick-v7-plasticity"
TESTS[hippocampus]="hip-v6 hip-v6-mcr4 quick-hip-projSeed2 quick-hip-delayconn quick-hip-multipopulation sonataconf-quick-hip-multipopulation"
TESTS[thalamus]="thalamus"
TESTS[mousify]="mousify quick-mousify-sonata"

PY_ONLY_TESTS="quick-hip-multipopulation scx-1k-v5-newparams quick-1k-v5-nodesets quick-scx-multi-circuit point-neuron sscx-v7-plasticity quick-v7-plasticity"

# Prepare spack (install+env)
source ci/spack_setup.sh || return $?

# Routines for installing
source ci/build.sh || return $?

# load test/check routines
source ci/testutils.sh

