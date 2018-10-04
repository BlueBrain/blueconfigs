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
        git clone $SPACK_REPO --single-branch
    fi
fi
export SPACK_ROOT=`pwd`/spack
export PATH=$SPACK_ROOT/bin:$PATH


################################### SETUP PACKAGE CONFIGS ##############################

mkdir -p $SPACK_ROOT/etc/spack/defaults/linux
cp $SPACK_ROOT/sysconfig/bb5/users/* $SPACK_ROOT/etc/spack/defaults/linux/

# Patch for modules suffix, otherwise clash
sed -i "s#hash_length: 0#hash_length: 8#g"  $SPACK_ROOT/etc/spack/defaults/linux/modules.yaml

set +x
spack module tcl refresh -y --delete-tree
source $SPACK_ROOT/share/spack/setup-env.sh


################################## BUILD REQUIRED PACKAGES #############################

# inside jenkins or slurm job we have to build neuron's nmodl separately
echo "======== Building Neurodamus  ========="
NEURODAMUS_OPTIONS="~coreneuron+syn2"
OPTIONS="^neuron+cross-compile+debug"

ND_MASTER="neurodamus@master$NEURODAMUS_OPTIONS"
ND_MASTER_NO_SYN2="neurodamus@master~coreneuron~syn2"
ND_HIPPOCAMPUS="neurodamus@hippocampus$NEURODAMUS_OPTIONS"
ND_PLASTICITY="neurodamus@plasticity~coreneuron"

echo -e "[$Blue INFO $ColorReset] Building $ND_MASTER"
spack install $ND_MASTER $OPTIONS
echo -e "[$Blue INFO $ColorReset] Building $ND_MASTER_NO_SYN2"
spack install $ND_MASTER_NO_SYN2 $OPTIONS
echo -e "[$Blue INFO $ColorReset] Building $ND_HIPPOCAMPUS"
spack install $ND_HIPPOCAMPUS $OPTIONS
echo -e "[$Blue INFO $ColorReset] Building $ND_PLASTICITY"
spack install $ND_PLASTICITY $OPTIONS

# reload module paths
source $SPACK_ROOT/share/spack/setup-env.sh

echo -e "[$Green OK $ColorReset] Environment successfully setup\n"


#################################### RUN TESTS ####################################

# list of simulations to run
# NOTE: scx-v5-gapjunctions is re-run without syn2 support since it's a very complete
#       test, loading synapses, projections and GJs, some with syn2 and nrn, other only nrn
tests_master=(scx-v5 scx-v6 scx-1k-v5 scx-2k-v6 scx-v5-gapjunctions scx-v5-bonus-minis)
#tests_master_no_syn2=(scx-v5-gapjunctions)
tests_plasticity=(scx-v5-plasticity)
tests_hippocampus=(hip-v6)

# list of simulation results
declare -A results
EXTENDED_RESULTS="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular"
results[scx-v5]="$EXTENDED_RESULTS/circuit-scx-v5/simulation"
results[scx-v6]="$EXTENDED_RESULTS/circuit-scx-v6/simulation"
results[scx-1k-v5]="$EXTENDED_RESULTS/circuit-1k/simulation"
results[scx-2k-v6]="$EXTENDED_RESULTS/circuit-2k/simulation"
results[scx-v5-gapjunctions]="$EXTENDED_RESULTS/circuit-scx-v5-gapjunctions/simulation"
results[scx-v5-bonus-minis]="$EXTENDED_RESULTS/circuit-scx-v5-bonus-minis/simulation"
results[scx-v5-plasticity]="$EXTENDED_RESULTS/circuit-scx-v5-plasticity/simulation"
results[hip-v6]="$EXTENDED_RESULTS/circuit-hip-v6/simulation"


echo "
=====================================================================
Running Tests
====================================================================="

run_test() {
    testname=$1
    neurodamus_version=$2
    echo -e "\n[$Blue INFO $ColorReset] Running test simulation: $testname ($neurodamus_version)"
    echo -e "[$Blue INFO $ColorReset] -----------------------"

    # load required modules
    module purge
    spack load $neurodamus_version

    # cd to corresponding directory and run test
    set -x
    cd $BLUECONFIG_DIR/$testname
    rm -rf $RESULTS && mkdir -p $RESULTS
    srun special $HOC_LIBRARY_PATH/init.hoc -mpi

    # sort the spikes and compare the output
    sort -n -k'1,1' -k2 < $RESULTS/out.dat > $RESULTS/out.sorted
    diff -wy --suppress-common-lines out.sorted $RESULTS/out.sorted

    # compare reports
    set +x
    for report in $(cd $RESULTS && ls *.bbp); do
        (set -x
         cmp ${results[$testname]}/$report $RESULTS/$report)
    done

    echo -e "[$Green PASS $ColorReset] Test $testname successfull"
}

# iterate over all test
for testname in "${tests_master[@]}"; do
    run_test $testname $ND_MASTER
done
for testname in "${tests_hippocampus[@]}"; do
    run_test $testname $ND_HIPPOCAMPUS
done
for testname in "${tests_plasticity[@]}"; do
    run_test $testname $ND_PLASTICITY
done
for testname in "${tests_master_no_syn2[@]}"; do
    run_test $testname $ND_MASTER_NO_SYN2
done

echo -e "[$Green SUCCESS $ColorReset] ALL TESTS PASSED"

