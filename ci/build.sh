#!/bin/bash
_THISDIR=$(readlink -f $(dirname $BASH_SOURCE))
source "$_THISDIR/envutils.sh"

install_neurodamus() (
set -e +x
declare ND_VERSIONS=${1:-"$TEST_VERSIONS"}

if [ -z "$ND_VERSIONS" ]; then
    log_error "No TEST_VERSIONS defined and no argument specifying version to install"
    return 1
fi
if [ -z "$SPACK_ROOT" ]; then
    log_error "No spack available"
    return 1
fi

for version in $ND_VERSIONS; do
    if [ -z "${VERSIONS[$version]}" ]; then
        log_error "Invalid version name: $version. Available: ${!VERSIONS[*]}"
        return 1
    fi
done

echo "
=====================================================================
Building required Neurodamus versions
====================================================================="


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

log_ok "Environment successfully setup"

) #eof install_neurodamus f
