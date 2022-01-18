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
    log "SPACK_ROOT is already set: $SPACK_ROOT"
    export LOCAL_SPACK=${SPACK_ROOT}
else
    export LOCAL_SPACK=${WORKSPACE}/spack
fi

module use /gpfs/bbp.cscs.ch/ssd/apps/bsd/modules/_meta
module load unstable git


############################# CLONE/SETUP REPOSITORY #############################

install_spack() (
    set -e
    spack spec zlib  # Bootstrap

    rm -rf $HOME/.spack   # CLEANUP SPACK CONFIGS
    SPACK_REPO=https://github.com/BlueBrain/spack.git
    SPACK_BRANCH=${SPACK_BRANCH:-"develop"}

    cd $WORKSPACE
    log "Installing SPACK. Cloning $SPACK_REPO spack --depth 1 -b $SPACK_BRANCH"
    git clone -c feature.manyFiles=true $SPACK_REPO spack --depth 1 -b $SPACK_BRANCH
    cp spack/bluebrain/sysconfig/bluebrain5/*.yaml spack/etc/spack/
)


spack_setup() (
    set -e
    if [[ ! -d "$DATADIR" && ! "$DRY_RUN" ]]; then
      log_error "DATADIR ($DATADIR) not found."
      return 1
    fi
    # Install a Spack environment if needed
    if [ -d $LOCAL_SPACK ]; then
        log_warn "Using existing spack at $LOCAL_SPACK"
    else
        install_spack
    fi

    source $LOCAL_SPACK/share/spack/setup-env.sh
    source "$_THISDIR/spack_patch.sh"
)


spack_setup || return $?
echo PATH=$PATH
log "Reloading spack config: source $LOCAL_SPACK/share/spack/setup-env.sh"
source $LOCAL_SPACK/share/spack/setup-env.sh
log_ok "Spack environment setup done"
