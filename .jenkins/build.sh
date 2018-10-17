#!/bin/bash
set -e

################################## BUILD REQUIRED PACKAGES #############################

# Patch mods name
sed -i "s#hash_length: 0#hash_length: 8#g"  $SPACK_ROOT/etc/spack/defaults/linux/modules.yaml

# inside jenkins or slurm job we have to build neuron's nmodl separately
echo "======== Building Neurodamus  ========="

echo -e "[$Blue INFO $ColorReset] Building $ND_MASTER $DEPENDENCIES_OPTIONS"
spack install $ND_MASTER $DEPENDENCIES_OPTIONS
echo -e "[$Blue INFO $ColorReset] Building $ND_MASTER_NO_SYN2 $DEPENDENCIES_OPTIONS"
spack install $ND_MASTER_NO_SYN2 $DEPENDENCIES_OPTIONS
echo -e "[$Blue INFO $ColorReset] Building $ND_HIPPOCAMPUS $DEPENDENCIES_OPTIONS"
spack install $ND_HIPPOCAMPUS $DEPENDENCIES_OPTIONS
echo -e "[$Blue INFO $ColorReset] Building $ND_PLASTICITY $DEPENDENCIES_OPTIONS"
spack install $ND_PLASTICITY $DEPENDENCIES_OPTIONS

echo "Updating modules"
spack module tcl refresh -y --delete-tree
source $SPACK_ROOT/share/spack/setup-env.sh

echo -e "[$Green OK $ColorReset] Environment successfully setup\n"
