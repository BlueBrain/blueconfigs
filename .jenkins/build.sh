#!/bin/bash
_THISDIR=$(readlink -f $(dirname $BASH_SOURCE))
source "$_THISDIR/envutils.sh"

install_neurodamus() (
set -e +x
echo "
=====================================================================
Building required Neurodamus versions
====================================================================="
if [[ -z "$1" && -z "$TEST_VERSIONS" ]]; then
    log_error "No TEST_VERSIONS defined and no argument specifying version to install"
    false
fi
if [ -z "$SPACK_ROOT" ]; then
    log_error "No spack available"
    false
fi

declare ND_VERSIONS=${1:-"$TEST_VERSIONS"}

for version in $ND_VERSIONS; do
    log "Building ${VERSIONS[$version]} $BUILD_OPTIONS  (version=$version)"
    if [ "$DRY_RUN" ]; then
        spack spec -I ${VERSIONS[$version]} $BUILD_OPTIONS
    else
        spack install --show-log-on-error ${VERSIONS[$version]} $BUILD_OPTIONS
    fi
done
if [ "$RUN_PY_TESTS" ]; then
    echo "Installing also $NEURODAMUS_PY_VERSION"
    if [ "$DRY_RUN" ]; then
        spack spec -I $NEURODAMUS_PY_VERSION
    else
        spack install --show-log-on-error $NEURODAMUS_PY_VERSION
    fi
fi

if [ ! "$DRY_RUN" ]; then
    log "Spack module refresh"
    spack module tcl refresh -y --delete-tree
fi

log_ok "Environment successfully setup"

) #eof install_neurodamus f

