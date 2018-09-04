#!/bin/bash
# NOTE: This file shall be sourced so that important variables are avail to other scripts
set -e
[ $ENVUTILS_LOADED ] || source "${BASH_SOURCE%/*}/envutils.sh"

############################## SPACK REPOSITORY #############################
[ $WORKSPACE ]

(set +x; echo "
=====================================================================
Preparing environment...
=====================================================================")

mkdir -p $HOME
pushd $HOME
rm -rf .spack   # CLEANUP SPACK CONFIGS

# CLONE SPACK REPOSITORY
if [ ! -d spack ]; then
    SPACK_REPO=https://github.com/BlueBrain/spack.git
    SPACK_BRANCH=${SPACK_BRANCH:-"develop"}
    git clone $SPACK_REPO --depth 1 -b $SPACK_BRANCH
fi

# Get back to workspace
popd

################################### PATCH SPACK CONFIGS ##############################

mkdir -p $SPACK_ROOT/etc/spack/defaults/linux
cp $SPACK_ROOT/sysconfig/bb5/users/* $SPACK_ROOT/etc/spack/defaults/linux/

# Spack patches to customize build
source "${BASH_SOURCE%/*}/spack_patch.sh"
