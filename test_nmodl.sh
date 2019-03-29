#!/bin/bash
set -ex
_THISDIR=$(readlink -f $(dirname $BASH_SOURCE))

# In jenkins mode set HOME to BUILD_HOME
export WORKSPACE=${WORKSPACE:-$_THISDIR}
export HOME=$WORKSPACE/BUILD_HOME
export SPACK_BRANCH="pr/sim_caliper"

# Prepare environment / spack
source $_THISDIR/.tests_setup.sh


# NMODL config
export TEST_VERSIONS=${TEST_VERSIONS:-"master hippocampus plasticity master_sympy hippocampus_sympy plasticity_sympy mousify_sympy"}
BUILD_OPTIONS="^neuron+cross-compile+debug %intel"

declare -A VERSIONS
VERSIONS[master]="neurodamus@master+coreneuron^coreneuron+nmodl~sympy+debug"
VERSIONS[hippocampus]="neurodamus@hippocampus+coreneuron^coreneuron+nmodl~sympy+debug"
VERSIONS[plasticity]="neurodamus@plasticity+coreneuron^coreneuron+nmodl~sympy+debug"
VERSIONS[master_sympy]="neurodamus@master+coreneuron^coreneuron+nmodl+sympy"
VERSIONS[hippocampus_sympy]="neurodamus@hippocampus+coreneuron^coreneuron+nmodl+sympy"
VERSIONS[plasticity_sympy]="neurodamus@plasticity+coreneuron^coreneuron+nmodl+sympy"
VERSIONS[mousify_sympy]="neurodamus@mousify+coreneuron^coreneuron+nmodl+sympy"

# list of simulations to run
# NOTE: scx-v5-gapjunctions is re-run without syn2 support since it's a very complete test
declare -A TESTS
TESTS[master]="scx-v5 scx-2k-v6 scx-v5-bonus-minis"
TESTS[hippocampus]="hip-v6"
TESTS[plasticity]="scx-v5-plasticity"
TESTS[master_sympy]="scx-v5 scx-2k-v6 scx-v5-bonus-minis"
TESTS[hippocampus_sympy]="hip-v6"
TESTS[plasticity_sympy]="scx-v5-plasticity"
TESTS[mousify_sympy]="mousify"


# Build req versions
install_neurodamus

(
    #git reset --hard
    source toolbox.sh
    for f in $(find . -name 'BlueConfig'); do
        blue_set Simulator NEURON $f
	blue_set OutputRoot output_neuron $f
        blue_comment Report $f
    done
)


run_all_tests


# Patch for CORENEURON and to disable reports
(
    #git reset --hard
    source toolbox.sh
    for f in $(find . -name 'BlueConfig'); do
        blue_set Simulator CORENEURON $f
	blue_set OutputRoot output_coreneuron $f
        blue_comment Report $f
    done
)

run_all_tests


echo -e "[$Green SUCCESS $ColorReset] ALL TESTS PASSED"
