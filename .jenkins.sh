#!/bin/bash
set -e

# if you want to run locally, set following
export WORKSPACE=/gpfs/bbp.cscs.ch/project/proj20/$USER-spack-test

############################### SETUP BUILD ENVIRONMENT ###############################
cd $WORKSPACE
mkdir -p $WORKSPACE/BUILD_HOME
export SOFTS_DIR_PATH=$WORKSPACE/INSTALL_HOME

################################ CLEANUP SPACK CONFIGS ################################
export HOME=$WORKSPACE/BUILD_HOME
cd $HOME
rm -rf blueconfigs spack $HOME/.spack

################################# CLONE SPACK REPOSITORY ##############################
git clone https://github.com/BlueBrain/spack.git
export SPACK_ROOT=`pwd`/spack
export PATH=$SPACK_ROOT/bin:$PATH
source $SPACK_ROOT/share/spack/setup-env.sh

################################### SETUP PACKAGE CONFIGS ##############################
mkdir -p $SPACK_ROOT/etc/spack/defaults/linux
cp $SPACK_ROOT/sysconfig/bb5/users/* $SPACK_ROOT/etc/spack/defaults/linux/

export MODULEPATH=/gpfs/bbp.cscs.ch/apps/compilers/modules/tcl/linux-rhel7-x86_64:$MODULEPATH
export MODULEPATH=/gpfs/bbp.cscs.ch/apps/tools/modules/tcl/linux-rhel7-x86_64:$MODULEPATH
module av hpe-mpi

################################## BUILD REQUIRED PACKAGES #############################
spack install -v neurodamus@master~coreneuron
spack install -v neurodamus@plasticity~coreneuron
spack install -v neurodamus@hippocampus~coreneuron

############################## CLONE BLUECONFIG REPOSITORY #############################
git clone ssh://bbpcode.epfl.ch/hpc/blueconfigs
BLUECONFIG_DIR=`pwd`/blueconfigs

#################################### RUN TESTS ####################################

# list of simulations to run
declare -A tests
tests[scx-testdata]="neurodamus@master~coreneuron"
tests[scx-v5]="neurodamus@master~coreneuron"
tests[scx-v6]="neurodamus@master~coreneuron"
tests[scx-v5-plasticity]="neurodamus@plasticity~coreneuron"
tests[hip-v6]="neurodamus@hippocampus~coreneuron"

# iterate over all test
for testname in "${!tests[@]}"
do
    echo "Running Test Simulation : $testname"

    # laod required modules
    module purge
    spack load ${tests[$testname]}

    # cd to corresponding directory and run test
    cd $BLUECONFIG_DIR/$testname
    srun special $HOC_LIBRARY_PATH/init.hoc -mpi

    # sort the spikes and compare the output
    cat out.dat | sort -k 1n,1n -k 2n,2n > out.sorted.new
    diff -w out.sorted out.sorted.new > diff.dat 2>&1
    if [ -s diff.dat ]
    then
        echo "$testname validation failed!"
        exit 1
    fi
done
