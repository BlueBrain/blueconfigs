#!/bin/bash
set -ex
source .jenkins/envutils.sh

# In jenkins mode set HOME to BUILD_HOME
export WORKSPACE=${WORKSPACE:-$_THISDIR}
export HOME=$WORKSPACE/BUILD_HOME

# Prepare environment / spack
_THISDIR=$(readlink -f $(dirname $BASH_SOURCE))
source $_THISDIR/.tests_setup.sh

# Build req versions
install_neurodamus

run_all_tests

set +ex
log "ALL TESTS PASSED" "SUCCESS" $Green
