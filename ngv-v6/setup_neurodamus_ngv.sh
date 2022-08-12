#!/bin/sh
#
# Script which automates the setting up of NGV environment
#

if [ -z "$1" ]; then
    echo "Please provide the destination dir. (Use . for the current dir)"
    exit 1
fi

set -xe
WORKSPACE="${WORKSPACE:-$PWD/$1}"
mkdir -p "$WORKSPACE"
cd $WORKSPACE
BUILD_HOME="${WORKSPACE}"
export SPACK_ROOT="${SPACK_ROOT:-${BUILD_HOME}/spack}"
SPACK_BRANCH=${SPACK_BRANCH:-"ngv_deploy"}
SPACK_REPO=https://github.com/BlueBrain/spack.git
export HOME=$WORKSPACE  # spack config doesnt get messed by user local configs
BASEDIR="$(dirname "$SPACK_ROOT")"

mkdir -p $BASEDIR && cd $BASEDIR
rm -rf .spack   # CLEANUP SPACK CONFIGS

if [ ! -d $SPACK_ROOT ]; then
    echo "Installing SPACK. Cloning $SPACK_REPO $SPACK_ROOT --depth 1 -b $SPACK_BRANCH"
    git clone $SPACK_REPO $SPACK_ROOT --depth 1 -b $SPACK_BRANCH
fi
export PATH=$SPACK_ROOT/bin:$PATH
spack --version

# Use BBP configs, including app upstream
echo "Using Upstream spack neurodamus"
cp /gpfs/bbp.cscs.ch/apps/hpc/jenkins/config/*.yaml $SPACK_ROOT/etc/spack/
upstreams_f="${SPACK_ROOT}/etc/spack/upstreams.yaml"
cur_upstreams=$(tail -n+2 $upstreams_f)

echo "
upstreams:
  applications:
    install_tree: /gpfs/bbp.cscs.ch/ssd/apps/hpc/jenkins/deploy/applications/latest
    modules:
      tcl: /gpfs/bbp.cscs.ch/ssd/apps/hpc/jenkins/deploy/applications/latest/modules
$cur_upstreams
" > "$upstreams_f"

spack install neurodamus-neocortex@develop +ngv+synapsetool~plasticity~coreneuron %intel

spack install py-neurodamus@develop

ln -s $SPACK_ROOT/opt/spack/*/*/py-neurodamus*/lib*/python3*/site-packages/neurodamus py-neurodamus

modules_dir=$(echo $SPACK_ROOT/share/spack/modules/*)

echo "
# Autogen file to load this NGV environment
module load unstable intel hpe-mpi
module use $modules_dir

module load neurodamus-neocortex
module load py-neurodamus py-bluepy
" > env_setup.sh

echo "Environment done. To activate please source env_setup.sh "

