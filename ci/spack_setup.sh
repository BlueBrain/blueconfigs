#!/bin/env bash
# NOTE: This file shall be sourced so that important variables are avail to other scripts
_THISDIR=$(readlink -f $(dirname $BASH_SOURCE))
source "$_THISDIR/envutils.sh"

echo "
=====================================================================
Preparing spack environment...
====================================================================="


[ "$WORKSPACE" ] || { log_error "Please define WORKSPACE"; return 1; }
[ "$DATADIR" ] || { log_error "Please define DATADIR"; return 1; }

# Give the use the possibility of running with an existing spack
if [[ "$SPACK_ROOT" ]]; then
    log_warn "Using pre-configured spack from $SPACK_ROOT"
    export LOCAL_SPACK=${SPACK_ROOT}
else
    # Install spack if we are using this from anywhere else other than CI
    export LOCAL_SPACK=${WORKSPACE}/spack
    export SPACK_SYSTEM_CONFIG_PATH=/gpfs/bbp.cscs.ch/ssd/apps/bsd/config  # latest config
    export SPACK_USER_CACHE_PATH=${WORKSPACE}/INSTALL
fi

log "Spack settings:
 - Path: $LOCAL_SPACK
 - SPACK_SYSTEM_CONFIG_PATH: $SPACK_SYSTEM_CONFIG_PATH
 - SPACK_USER_CACHE_PATH: $SPACK_USER_CACHE_PATH"

module use /gpfs/bbp.cscs.ch/ssd/apps/bsd/pulls/1765/2022-11-29/config/modules/_meta
module load unstable git


############################# CLONE/SETUP REPOSITORY #############################

install_spack() (
    # Install spack if we are using this from anywhere else other than CI
    set -e
    rm -rf $HOME/.spack   # CLEANUP SPACK CONFIGS
    SPACK_REPO=https://github.com/BlueBrain/spack.git
    SPACK_BRANCH=${SPACK_BRANCH:-"develop"}

    cd $WORKSPACE
    log "Installing SPACK. Cloning $SPACK_REPO spack --depth 1 -b $SPACK_BRANCH"
    git clone -c feature.manyFiles=true $SPACK_REPO spack --depth 1 -b $SPACK_BRANCH
    rm -f spack/etc/spack/*.yaml
    cp spack/bluebrain/sysconfig/bluebrain5/*.yaml spack/etc/spack/
)


spack_setup() (
    set -e
    if [[ ! -d "$DATADIR" && ! "$DRY_RUN" ]]; then
      log_error "DATADIR ($DATADIR) not found."
      return 1
    fi
    # Install a Spack environment if needed
    if [ ! -d $LOCAL_SPACK ]; then
        install_spack
    fi

    set -e
    source $LOCAL_SPACK/share/spack/setup-env.sh

    set -e
    source "$_THISDIR/spack_patch.sh"

    log "Testing Spack and bootstrap if needed"
    spack spec -I zlib
)


spack_setup || return 1
set -e
echo PATH=$PATH
log "Reloading spack config: source $LOCAL_SPACK/share/spack/setup-env.sh"
source $LOCAL_SPACK/share/spack/setup-env.sh
# used when constructing reference file paths
spack -c "packages:zlib:requires:'%${BUILD_COMPILER}'" spec -I zlib
BUILD_COMPILER_VERSION=$(spack -c "packages:zlib:requires:'%${BUILD_COMPILER}'" spec -I zlib | sed -ne "s#.*%${BUILD_COMPILER}@\([0-9\.]\+\).*#\1#p")
log_ok "Spack environment setup done"
