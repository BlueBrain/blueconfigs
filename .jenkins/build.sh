#!/bin/bash
_SET=$-
set -e
[ $ENVUTILS_LOADED ] || source "${BASH_SOURCE%/*}/envutils.sh"
set +x
source $SPACK_ROOT/share/spack/setup-env.sh

# If reusing software, be sure modules uptodate
spack module tcl refresh -y --delete-tree

################################## BUILD REQUIRED PACKAGES #############################

# inside jenkins or slurm job we have to build neuron's nmodl separately
echo "
Building Neurodamus...
======================"

for version in $TEST_VERSIONS; do
    echo -e "[$Blue INFO $ColorReset] Building ${VERSIONS[$version]} $BUILD_OPTIONS"
    spack install ${VERSIONS[$version]} $BUILD_OPTIONS
done

echo -e "[$Green OK $ColorReset] Environment successfully setup\n"

# After install MODULEPATH has to be set again (bug?)
source $SPACK_ROOT/share/spack/setup-env.sh

set -$_SET
