#!/bin/bash
set -xe

############################## BLUECONFIG REPOSITORY #############################

# NOTE: if you want to run locally on BB5, set following
# export WORKSPACE=$HOME/$USER-spack-sim-test
WORKSPACE=`pwd`
BLUECONFIG_DIR=`pwd`


############################### SETUP BUILD ENVIRONMENT ###############################

mkdir -p $WORKSPACE/HOME_DIR
export SOFTS_DIR_PATH=$WORKSPACE/softs


################################ CLEANUP SPACK CONFIGS ################################

export HOME=$WORKSPACE/HOME_DIR
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


################################## BUILD REQUIRED PACKAGES #############################

# inside jenkins we have to build neuron's nmodl separately
OPTIONS=""
if [ -n "$JENKINS_URL" ]; then
    OPTIONS="^neuron+cross-compile"
fi

spack install neurodamus@master~coreneuron $OPTIONS
spack install neurodamus@plasticity~coreneuron $OPTIONS
spack install neurodamus@hippocampus~coreneuron $OPTIONS

# reload module paths
source $SPACK_ROOT/share/spack/setup-env.sh


#################################### RUN TESTS ####################################

# list of simulations to run
declare -A tests
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
done

echo "\n--------- ALL TESTS PASSED ---------\n"
