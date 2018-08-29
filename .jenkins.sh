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
rm -rf spack $HOME/.spack


################################# CLONE SPACK REPOSITORY ##############################

git clone https://github.com/BlueBrain/spack.git
export SPACK_ROOT=`pwd`/spack
export PATH=$SPACK_ROOT/bin:$PATH


################################### SETUP PACKAGE CONFIGS ##############################

mkdir -p $SPACK_ROOT/etc/spack/defaults/linux
cp $SPACK_ROOT/sysconfig/bb5/users/* $SPACK_ROOT/etc/spack/defaults/linux/
source $SPACK_ROOT/share/spack/setup-env.sh


################################## BUILD REQUIRED PACKAGES #############################

# inside jenkins or slurm job we have to build neuron's nmodl separately
OPTIONS="^neuron+cross-compile+debug"

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
tests[scx-v5-gapjunctions]="neurodamus@master~coreneuron"
tests[hip-v6]="neurodamus@hippocampus~coreneuron"

# list of simulation results
declare -A results
results[scx-v5]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-scx-v5/simulation"
results[scx-v6]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-scx-v6/simulation"
results[scx-v5-plasticity]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-scx-v5-plasticity/simulation"
results[scx-v5-gapjunctions]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-scx-v5-gapjunctions/simulation"
results[hip-v6]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-hip-v6/simulation"


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

    # compare reports
    find . -name "*.bbp" | while read report; do
        diff $report ${results[$testname]}/$report
    done

done

echo "\n--------- ALL TESTS PASSED ---------\n"
