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

if [ -d spack ]; then
    (cd spack && git pull && git reset --hard HEAD)
else
    git clone https://github.com/BlueBrain/spack.git
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
OPTIONS="^neuron+cross-compile+debug"

echo -e "[$Blue INFO $ColorReset] Building neurodamus@master~coreneuron"
spack install neurodamus@master~coreneuron $OPTIONS
echo -e "[$Blue INFO $ColorReset] Building neurodamus@plasticity~coreneuron"
spack install neurodamus@plasticity~coreneuron $OPTIONS
echo -e "[$Blue INFO $ColorReset] Building neurodamus@hippocampus~coreneuron"
spack install neurodamus@hippocampus~coreneuron $OPTIONS
#spack install neurodamus@pydamus~coreneuron $OPTIONS

# reload module paths
source $SPACK_ROOT/share/spack/setup-env.sh

echo -e "[$Green OK $ColorReset] Environment successfully setup\n"

#################################### RUN TESTS ####################################

# list of simulations to run
declare -A tests
tests[scx-v5]="neurodamus@master~coreneuron"
tests[scx-v6]="neurodamus@master~coreneuron"
tests[scx-1k-v5]="neurodamus@master~coreneuron"
tests[scx-2k-v6]="neurodamus@master~coreneuron"
tests[scx-v5-plasticity]="neurodamus@plasticity~coreneuron"
tests[scx-v5-gapjunctions]="neurodamus@master~coreneuron"
tests[hip-v6]="neurodamus@hippocampus~coreneuron"
# Python neurodamus
#tests[pydamus-scx-v6]="neurodamus@pydamus~coreneuron"
#tests[pydamus-scx-v5-gapjunctions]="neurodamus@pydamus~coreneuron"

# list of simulation results
declare -A results
results[scx-v5]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-scx-v5/simulation"
results[scx-v6]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-scx-v6/simulation"
results[scx-1k-v5]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-1k/simulation"
results[scx-2k-v6]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-2k/simulation"
results[scx-v5-plasticity]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-scx-v5-plasticity/simulation"
results[scx-v5-gapjunctions]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-scx-v5-gapjunctions/simulation"
results[hip-v6]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-hip-v6/simulation"
results[pydamus-scx-v6]=results[scx-v6]
results[pydamus-scx-v5-gapjunctions]=results[scx-v5-gapjunctions]


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



