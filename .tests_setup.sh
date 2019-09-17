#!/bin/bash
source .jenkins/envutils.sh

# Test parameters eventually defined by Jenkins (env vars)
set +x
export WORKSPACE=${WORKSPACE:-"`pwd`"}
export TEST_VERSIONS=${TEST_VERSIONS:-"neocortex ncx_bare ncx_plasticity hippocampus thalamus mousify"}
export SPACK_BRANCH=${SPACK_BRANCH:-"develop"}
export RUN_PY_TESTS=${RUN_PY_TESTS:-"no"}
log "WORKSPACE=$WORKSPACE; TEST_VERSIONS=$TEST_VERSIONS; SPACK_BRANCH=$SPACK_BRANCH; RUN_PY_TESTS=$RUN_PY_TESTS" "DBG"

# Test definitions
DATADIR="/gpfs/bbp.cscs.ch/project/proj12/jenkins"
EXTRA_VARIANT="$ND_VARIANT+python"
BUILD_OPTIONS="${BUILD_OPTIONS:-"^neuron+debug"}"
DEFAULT_VARIANT="~plasticity+coreneuron+synapsetool"
CORENRN_DEP="^coreneuron+debug"
log "DATADIR=$DATADIR; EXTRA_VARIANT=$EXTRA_VARIANT; BUILD_OPTIONS=$BUILD_OPTIONS; DEFAULT_VARIANT=$DEFAULT_VARIANT; CORENRN_DEP=$CORENRN_DEP" DBG

declare -A VERSIONS
# Master is a plain v5+v6 version
VERSIONS[neocortex]="neurodamus-neocortex%intel$DEFAULT_VARIANT$EXTRA_VARIANT $CORENRN_DEP"
VERSIONS[ncx_bare]="neurodamus-neocortex%intel~plasticity~coreneuron~synapsetool$EXTRA_VARIANT"
VERSIONS[ncx_plasticity]="neurodamus-neocortex%intel+plasticity+coreneuron+synapsetool$EXTRA_VARIANT $CORENRN_DEP"
VERSIONS[hippocampus]="neurodamus-hippocampus%intel$EXTRA_VARIANT"
VERSIONS[thalamus]="neurodamus-thalamus%intel$EXTRA_VARIANT"
VERSIONS[mousify]="neurodamus-mousify%intel$EXTRA_VARIANT"

# list of simulations to run
declare -A TESTS
TESTS[neocortex]="scx-v5 scx-v6 scx-1k-v5 scx-2k-v6 scx-v5-gapjunctions scx-v5-bonus-minis"
TESTS[ncx_bare]="quick-v5-gaps quick-v6 quick-v5-multisplit"
TESTS[ncx_plasticity]="scx-v5-plasticity"
TESTS[hippocampus]="hip-v6 hip-v6-mcr4"
TESTS[thalamus]="thalamus"
TESTS[mousify]="mousify"

# Prepare spack (install+env)
source .jenkins/spack_setup.sh

# Routines for installing
source .jenkins/build.sh

# load test/check routines
source .jenkins/testutils.sh

set -$_setbk

