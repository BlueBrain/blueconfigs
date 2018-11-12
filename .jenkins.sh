#!/bin/bash
set -ex
_THISDIR=$(dirname $BASH_SOURCE)

# Prepare environment / spack
source $_THISDIR/.tests_setup.sh

# Build req versions
install_neurodamus

run_all_tests

echo -e "[$Green SUCCESS $ColorReset] ALL TESTS PASSED"
