#!/bin/bash
set -ex
_THISDIR=$(readlink -f $(dirname $BASH_SOURCE))

# In jenkins mode set HOME to BUILD_HOME
export WORKSPACE=${WORKSPACE:-$_THISDIR}
export HOME=$WORKSPACE/BUILD_HOME

# Prepare environment / spack
source $_THISDIR/.tests_setup.sh

# Build req versions
install_neurodamus

run_all_tests

echo -e "[$Green SUCCESS $ColorReset] ALL TESTS PASSED"
