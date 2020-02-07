#!/bin/bash
# NOTE: This file shall be sourced so that important variables are avail to other scripts
_THISDIR=$(readlink -f $(dirname $BASH_SOURCE))
source "$_THISDIR/envutils.sh"

echo "
=====================================================================
Preparing spack environment...
====================================================================="


[ "$WORKSPACE" ] || { log_error "Please define WORKSPACE"; return 1; }
[ "$DATADIR" ] || { log_error "Please define DATADIR"; return 1; }

export SPACK_INSTALL_PREFIX="${SPACK_INSTALL_PREFIX:-${WORKSPACE}/INSTALL_HOME}"
export SOFTS_DIR_PATH=$SPACK_INSTALL_PREFIX  # Deprecated, but might still be reqd

# Give the use the possibility of running with an existing spack
if [[ "$USE_SYSTEM_SPACK" && "$SPACK_ROOT" ]]; then
    log_warn "Using system spack at $SPACK_ROOT"
    return
fi

DEVEL_DEPLOY=$DATADIR/devel_builds_04-2019/
BUILD_HOME="${WORKSPACE}/BUILD_HOME"
export SPACK_ROOT="${BUILD_HOME}/spack"
log "SPACK_INSTALL_PREFIX=$SPACK_INSTALL_PREFIX; BUILD_HOME=$BUILD_HOME" DBG


# ENV SETUP

# TODO: /usr/bin was added as a quickfix due to git dependencies probs
export PATH=$SPACK_ROOT/bin/spack:/usr/bin:$PATH

# MODULES
# Use spack only modules. Last one is added by changing MODULEPATH since it might not exist yet
module purge
unset MODULEPATH
source /gpfs/bbp.cscs.ch/apps/hpc/jenkins/config/modules.sh
export MODULEPATH=$SPACK_INSTALL_PREFIX/modules/tcl/linux-rhel7-x86_64:$MODULEPATH

_external_pkg_tpl='
  ${PKG_NAME}:
    version: [${PKG_VERSION}]
    paths:
      ${PKG_NAME}@${PKG_VERSION}${PKG_VARIANT}: ${PKG_PATH}'
_external_pkg_module_tpl="$_external_pkg_tpl"'
    modules:
      ${PKG_NAME}@${PKG_VERSION}${PKG_VARIANT}: ${PKG_MODULE}'



############################# CLONE/SETUP REPOSITORY #############################

install_spack() (
    set -e
    BASEDIR="$(dirname "$SPACK_ROOT")"
    mkdir -p $BASEDIR && cd $BASEDIR
    rm -rf .spack   # CLEANUP SPACK CONFIGS
    SPACK_REPO=https://github.com/BlueBrain/spack.git
    SPACK_BRANCH=${SPACK_BRANCH:-"support/jan2020"}

    log "Installing SPACK. Cloning $SPACK_REPO $SPACK_ROOT --depth 1 -b $SPACK_BRANCH"
    git clone $SPACK_REPO $SPACK_ROOT --depth 1 -b $SPACK_BRANCH
    # Use BBP configs
    cp /gpfs/bbp.cscs.ch/apps/hpc/jenkins/config/*.yaml $SPACK_ROOT/etc/spack/

    # Use applications upstream
    echo "upstreams:
  applications:
    install_tree: /gpfs/bbp.cscs.ch/apps/hpc/jenkins/deploy/applications/2020-02-01/
    modules:
      tcl: /gpfs/bbp.cscs.ch/apps/hpc/jenkins/deploy/applications/2020-02-01/modules
$(tail -n +2 $SPACK_ROOT/etc/spack/upstreams.yaml)" > $SPACK_ROOT/etc/spack/upstreams.yaml

    # Avoid clash. Dont autoload
    sed -i 's#hash_length:.*#hash_length: 6#;/autoload/d' $SPACK_ROOT/etc/spack/modules.yaml
)


spack_setup() (
    set -e
    # Install a Spack environment if needed
    if [ -d $SPACK_ROOT ]; then
        log_warn "Using existing spack at $SPACK_ROOT"
    else
        install_spack
    fi

    # PATCH SPACK sources
    source "$_THISDIR/spack_patch.sh"
    log_ok "Spack environment setup done"
)


spack_setup

