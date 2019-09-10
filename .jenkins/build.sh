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

log "Spack module refresh"
spack module tcl refresh -y --delete-tree

declare ND_VERSIONS=${1:-"$TEST_VERSIONS"}

for version in $ND_VERSIONS; do
    log "Building ${VERSIONS[$version]} $BUILD_OPTIONS  (version=$version)"
    spack spec -I ${VERSIONS[$version]} $BUILD_OPTIONS
    spack install --show-log-on-error ${VERSIONS[$version]} $BUILD_OPTIONS
done

log_ok "Environment successfully setup"

) #eof install_neurodamus f

