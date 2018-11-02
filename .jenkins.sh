#!/bin/bash
set -ex

#Set the SPACK_BRANCH eventually used for testing new devel neurodamus branches
SPACK_BRANCH=$(echo "$GERRIT_TOPIC" | grep 'neurodamus-test-spack-') || true

NEURODAMUS_OPTIONS="~coreneuron+syn2 %intel"
DEPENDENCIES_OPTIONS="^neuron+cross-compile+debug %intel"

ND_MASTER="neurodamus@master$NEURODAMUS_OPTIONS"
ND_MASTER_NO_SYN2="neurodamus@master~coreneuron~syn2"
ND_HIPPOCAMPUS="neurodamus@hippocampus$NEURODAMUS_OPTIONS"
ND_PLASTICITY="neurodamus@plasticity+coreneuron"

# list of simulations to run
# NOTE: scx-v5-gapjunctions is re-run without syn2 support since it's a very complete
#       test, loading synapses, projections and GJs, some with syn2 and nrn, other only nrn
tests_master_debug=(scx-v5-gapjunctions)
tests_master=(scx-v5)
tests_master=(scx-v5 scx-v6 scx-1k-v5 scx-2k-v6 scx-v5-gapjunctions scx-v5-bonus-minis)
tests_master_no_syn2=(scx-v5-gapjunctions)
tests_plasticity=(scx-v5-plasticity)
tests_hippocampus=(hip-v6)


## Prepare env
source .jenkins/testutils.sh
source .jenkins/envsetup.sh

# Build req versions
source .jenkins/build.sh

# iterate over all test
#for testname in "${tests_master_debug[@]}"; do
#    run_debug $testname "$ND_MASTER"
#done
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
