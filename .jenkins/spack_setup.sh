#!/bin/bash
# NOTE: This file shall be sourced so that important variables are avail to other scripts
_set=$-
set -e
[ $ENVUTILS_LOADED ] || source "${BASH_SOURCE%/*}/envutils.sh"

if [ $SPACK_ROOT ]; then
    _BASEDIR=$(dirname "$SPACK_ROOT")
else
    echo "Warning: Installing spack to HOME: $HOME"
    _BASEDIR=$HOME
    export SPACK_ROOT=$HOME/spack
fi

DATADIR=${DATADIR:-"/gpfs/bbp.cscs.ch/project/proj12/jenkins"}


############################## SPACK REPOSITORY #############################
(set +x; echo "
=====================================================================
Preparing spack environment...
=====================================================================")

mkdir -p $_BASEDIR
pushd $_BASEDIR
rm -rf .spack   # CLEANUP SPACK CONFIGS

# Create a Spack environment, cloning and patching
if [ ! -d $SPACK_ROOT ]; then
    SPACK_REPO=https://github.com/BlueBrain/spack.git
    SPACK_BRANCH=${SPACK_BRANCH:-"develop"}
    git clone $SPACK_REPO $SPACK_ROOT --depth 1 -b $SPACK_BRANCH

    # Patch to bbp configs
    mkdir -p $SPACK_ROOT/etc/spack/defaults/linux
    cp $SPACK_ROOT/sysconfig/bb5/users/* $SPACK_ROOT/etc/spack/defaults/linux/

    # Use develop packages.yaml
    cp $DATADIR/devel_builds/packages.yaml $SPACK_ROOT/etc/spack/defaults/linux/

    # Patch for modules suffix, otherwise clash
    sed -i "s#hash_length: 0#hash_length: 8#g" $SPACK_ROOT/etc/spack/defaults/linux/modules.yaml
fi

# Get back to workspace
popd

################################### PATCH SPACK CONFIGS ##############################

# Spack patches to customize build
source "${BASH_SOURCE%/*}/spack_patch.sh"

# spack env
set +x
source $SPACK_ROOT/share/spack/setup-env.sh

# restore
set +e -$_set
