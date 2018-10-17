#!/bin/bash
# NOTE: This file shall be sourced so that important variables are avail to other scripts
set -e

############################## SPACK REPOSITORY #############################
export WORKSPACE=`pwd`

echo "
=====================================================================
Preparing environment...
====================================================================="

mkdir -p $WORKSPACE/HOME_DIR
export SOFTS_DIR_PATH=$WORKSPACE/softs

export HOME=$WORKSPACE/HOME_DIR
pushd $HOME
rm -rf $HOME/.spack   # CLEANUP SPACK CONFIGS

# CLONE SPACK REPOSITORY

if [ ! -d spack ]; then
    SPACK_REPO=https://github.com/BlueBrain/spack.git
    if [ $SPACK_BRANCH ]; then
        git clone $SPACK_REPO --depth 1 -b $SPACK_BRANCH
    else
        git clone $SPACK_REPO --depth 1
    fi
fi
export SPACK_ROOT=`pwd`/spack
export PATH=$SPACK_ROOT/bin:$PATH

# Get back to workspace
popd

################################### PATCH SPACK CONFIGS ##############################

mkdir -p $SPACK_ROOT/etc/spack/defaults/linux
cp $SPACK_ROOT/sysconfig/bb5/users/* $SPACK_ROOT/etc/spack/defaults/linux/

# Use develop packages.yaml
cp /gpfs/bbp.cscs.ch/project/proj12/jenkins/devel_builds/packages.yaml $SPACK_ROOT/etc/spack/defaults/linux/

# Patch for modules suffix, otherwise clash
sed -i "s#hash_length: 0#hash_length: 8#g"  $SPACK_ROOT/etc/spack/defaults/linux/modules.yaml

set +x
source $SPACK_ROOT/share/spack/setup-env.sh
