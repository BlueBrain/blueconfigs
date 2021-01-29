#!/bin/bash
set -e
source ../toolbox.sh
configfile_bk "$1"

outputdir="${2:-output}"

export OMP_NUM_THREADS=1

# Test two scanarios
#  - multicycle via BlueConfig option
#  - multicycle via CLI (neurodamus-py)
#
# Run first the simulation with neurodamus HOC or py-neurodamus and compare the output to the reference.
# Then run the simulation with neurodamus-py and it's CLI option. The output is checked when the script
# returns.

# Test the multicycle execution with Neurodamus HOC

cp "$blueconfig" "${blueconfig}_py"

blue_set ModelBuildingSteps 2 $blueconfig  # Build the model for CoreNeuron in 2 steps
blue_set Simulator CORENEURON $blueconfig
blue_set OutputRoot "${outputdir}_bc" $blueconfig # Save output in different folder to compare later
head -n30 $blueconfig

run_blueconfig $blueconfig

# Compare the results of the Neurodamus HOC simulation first
test_check_results "${outputdir}_bc" "${REF_RESULTS["quick-v5-plasticity"]}"


# Test the multicycle execution with Neurodamus-py and CLI opt, n_steps=12
# No.(cells/cycle) << No.(ranks), test the creation of dummy cells for coreneuron data

module load py-neurodamus

blue_set Simulator CORENEURON ${blueconfig}_py
RUN_PY_TESTS=yes run_blueconfig "${blueconfig}_py" "--modelbuilding-steps=12"

