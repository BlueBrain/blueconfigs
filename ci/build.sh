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

spack env remove -y piherrus || true
spack env create --without-view piherrus
spack env activate piherrus

spack add $NEURODAMUS_PY_VERSION
for version in $ND_VERSIONS; do
    spack add ${VERSIONS[$version]} $BUILD_OPTIONS
done

spack config add concretizer:unify:when_possible
spack config add concretizer:reuse:false

spack config add "modules:default:tcl:include:[py-neurodamus@develop,neurodamus-neocortex+ngv]"

spack config blame concretizer
spack config blame config
spack config blame modules

spack concretize -f

if [ -z "$DRY_RUN" ]; then
    spack fetch -m
    spack env depfile > Makefile
    make -j ${SLURM_CPUS_PER_TASK:-$SLURM_CPUS_PER_NODE}
fi

spack_sha=$($SPACK_ROOT/bluebrain/deployment/bin/installed-hashes|awk '/[^^]py-neurodamus/{print $1}')
spack module tcl refresh -y $spack_sha

log_ok "Neurodamus installed successfully. You may reload spack env to find modules"

) #eof install_neurodamus f

