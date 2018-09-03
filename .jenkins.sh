#!/bin/bash
set -e

Red='\033[0;31m'
Blue='\033[0;34m'
Green='\033[0;32m'
ColorReset='\033[0m'

error() {
    set +x
    echo -e "[$Red FATAL $ColorReset] Command returned $1."
    exit 1
}

trap 'error ${?}' ERR


############################## BLUECONFIG REPOSITORY #############################

# NOTE: if you want to run locally on BB5, set following
# export WORKSPACE=$HOME/$USER-spack-sim-test
WORKSPACE=`pwd`
BLUECONFIG_DIR=`pwd`
RESULTS=output


echo "
=====================================================================
Preparing environment...
====================================================================="

set -x

############################### SETUP BUILD ENVIRONMENT ###############################

mkdir -p $WORKSPACE/HOME_DIR
export SOFTS_DIR_PATH=$WORKSPACE/softs


################################ CLEANUP SPACK CONFIGS ################################

export HOME=$WORKSPACE/HOME_DIR
cd $HOME
rm -rf $HOME/.spack


################################# CLONE SPACK REPOSITORY ##############################

if [ ! -d spack ]; then
    SPACK_REPO=https://github.com/BlueBrain/spack.git
    if [ $SPACK_BRANCH ]; then
        git clone $SPACK_REPO --single-branch -b $SPACK_BRANCH
    else
        git clone $SPACK_REPO --single_branch
    fi
fi
export SPACK_ROOT=`pwd`/spack
export PATH=$SPACK_ROOT/bin:$PATH


################################### SETUP PACKAGE CONFIGS ##############################

mkdir -p $SPACK_ROOT/etc/spack/defaults/linux
cp $SPACK_ROOT/sysconfig/bb5/users/* $SPACK_ROOT/etc/spack/defaults/linux/
set +x
source $SPACK_ROOT/share/spack/setup-env.sh

################################## BUILD REQUIRED PACKAGES #############################

# inside jenkins or slurm job we have to build neuron's nmodl separately
echo "======== Building Neurodamus with Support for SynapseTool ========="
NEURODAMUS_OPTIONS="~coreneuron+syn2"
OPTIONS="^neuron+cross-compile+debug"

ND_MASTER="neurodamus@master$NEURODAMUS_OPTIONS"
ND_HIPPOCAMPUS="neurodamus@hippocampus$NEURODAMUS_OPTIONS"
ND_PLASTICITY="neurodamus@plasticity~coreneuron"

echo -e "[$Blue INFO $ColorReset] Building $ND_MASTER"
spack install $ND_MASTER $OPTIONS
echo -e "[$Blue INFO $ColorReset] Building $ND_HIPPOCAMPUS"
spack install $ND_HIPPOCAMPUS $OPTIONS
echo -e "[$Blue INFO $ColorReset] Building $ND_PLASTICITY"
spack install $ND_PLASTICITY $OPTIONS
#spack install neurodamus@pydamus~coreneuron $OPTIONS

# reload module paths
source $SPACK_ROOT/share/spack/setup-env.sh

echo -e "[$Green OK $ColorReset] Environment successfully setup\n"

#################################### RUN TESTS ####################################

# list of simulations to run
declare -A tests
tests[scx-v5]=$ND_MASTER
tests[scx-v6]=$ND_MASTER
tests[scx-1k-v5]=$ND_MASTER
tests[scx-2k-v6]=$ND_MASTER
tests[scx-v5-plasticity]=$ND_PLASTICITY
tests[scx-v5-gapjunctions]=$ND_MASTER
tests[hip-v6]=$ND_HIPPOCAMPUS

# list of simulation results
declare -A results
EXTENDED_RESULTS="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular"
results[scx-v5]="$EXTENDED_RESULTS/circuit-scx-v5/simulation"
results[scx-v6]="$EXTENDED_RESULTS/circuit-scx-v6/simulation"
results[scx-1k-v5]="$EXTENDED_RESULTS/circuit-1k/simulation"
results[scx-2k-v6]="$EXTENDED_RESULTS/circuit-2k/simulation"
results[scx-v5-plasticity]="$EXTENDED_RESULTS/circuit-scx-v5-plasticity/simulation"
results[scx-v5-gapjunctions]="$EXTENDED_RESULTS/circuit-scx-v5-gapjunctions/simulation"
results[hip-v6]="$EXTENDED_RESULTS/circuit-hip-v6/simulation"


echo "
=====================================================================
Running Tests
====================================================================="

# iterate over all test
for testname in "${!tests[@]}"
do
    echo -e "\n[$Blue INFO $ColorReset] Running test simulation: $testname"
    echo -e "[$Blue INFO $ColorReset] -----------------------"

    # load required modules
    module purge
    spack load ${tests[$testname]}

    # cd to corresponding directory and run test
    set -x
    cd $BLUECONFIG_DIR/$testname
    rm -rf $RESULTS && mkdir -p $RESULTS
    srun special $HOC_LIBRARY_PATH/init.hoc -mpi > $RESULTS/run.log 2>&1

    # sort the spikes and compare the output
    sort -n -k'1,1' -k2 < $RESULTS/out.dat > $RESULTS/out.sorted
    diff -w out.sorted $RESULTS/out.sorted > diff.dat 2>&1

    # compare reports
    set +x
    for report in $(cd $RESULTS && ls *.bbp); do
        (set -x
         cmp ${results[$testname]}/$report $RESULTS/$report)
    done

    echo -e "[$Green PASS $ColorReset] Test $testname successfull"
done

echo -e "[$Green SUCCESS $ColorReset] ALL TESTS PASSED"


