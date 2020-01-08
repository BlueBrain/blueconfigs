#!/bin/bash
set -ex
source .jenkins/envutils.sh

# In jenkins mode set HOME to BUILD_HOME
export WORKSPACE=${WORKSPACE:-$_THISDIR}
export HOME=$WORKSPACE/BUILD_HOME

# Prepare environment / spack
_THISDIR=$(readlink -f $(dirname $BASH_SOURCE))
source $_THISDIR/.tests_setup.sh

# Drop tests which wont currently run
#mv quick-v5-multisplit/test_coreneuron_delmodeldata.sh quick-v5-multisplit/_test_coreneuron_delmodeldata.sh
mv quick-v5-multisplit/test_multisplit.sh quick-v5-multisplit/_test_multisplit.sh

# Build req versions
install_neurodamus

run_all_tests

set +ex
log "ALL TESTS PASSED" "SUCCESS" $Green
