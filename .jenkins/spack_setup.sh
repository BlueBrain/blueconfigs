#!/bin/bash
# NOTE: This file shall be sourced so that important variables are avail to other scripts
_set=$-
set -e
[ $ENVUTILS_LOADED ] || source "${BASH_SOURCE%/*}/envutils.sh"

if [ $SPACK_ROOT ]; then
    _BASEDIR=$(dirname "$SPACK_ROOT")
else
    _BASEDIR=$HOME
    export SPACK_ROOT=$HOME/spack
fi


############################## SPACK REPOSITORY #############################
(set +x; echo "
=====================================================================
Preparing spack environment...
=====================================================================")

mkdir -p $_BASEDIR
pushd $_BASEDIR
rm -rf .spack   # CLEANUP SPACK CONFIGS

# CLONE SPACK REPOSITORY
if [ ! -d $SPACK_ROOT ]; then
    SPACK_REPO=https://github.com/BlueBrain/spack.git
    SPACK_BRANCH=${SPACK_BRANCH:-"develop"}
    git clone $SPACK_REPO $SPACK_ROOT --depth 1 -b $SPACK_BRANCH
fi

# Get back to workspace
popd

################################### PATCH SPACK CONFIGS ##############################

mkdir -p $SPACK_ROOT/etc/spack/defaults/linux
cp $SPACK_ROOT/sysconfig/bb5/users/* $SPACK_ROOT/etc/spack/defaults/linux/

# Spack patches to customize build
source "${BASH_SOURCE%/*}/spack_patch.sh"

# restore
set +e -$_set
