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

BUILD_HOME="${WORKSPACE}/BUILD_HOME"
log "BUILD_HOME=$BUILD_HOME" DBG
export LOCAL_SPACK=${BUILD_HOME}/spack

# MODULES
module purge
module load spack unstable git


############################# CLONE/SETUP REPOSITORY #############################

install_spack() (
    set -e
    rm -rf $HOME/.spack   # CLEANUP SPACK CONFIGS
    SPACK_REPO=https://github.com/BlueBrain/spack.git
    SPACK_BRANCH=${SPACK_BRANCH:-"develop"}

    mkdir -p $BUILD_HOME
    cd $BUILD_HOME
    log "Installing SPACK. Cloning $SPACK_REPO spack --depth 1 -b $SPACK_BRANCH"
    git clone -c feature.manyFiles=true $SPACK_REPO spack --depth 1 -b $SPACK_BRANCH
    cp spack/bluebrain/sysconfig/bluebrain5/*.yaml spack/etc/spack/
    echo "modules:
  tcl:
    naming_scheme: '\${PACKAGE}/\${VERSION}'
    whitelist:
      - '@:'
    " > spack/etc/spack/modules.yaml
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
