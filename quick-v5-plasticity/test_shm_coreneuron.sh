#!/bin/bash
set -e
source ../toolbox.sh
configfile_bk "$1"

outputdir="${2:-output}"

export OMP_NUM_THREADS=1

# Test two scenarios using neurodamus-py:
#  - SHM file transfer on a single pass
#  - SHM file transfer with multicycle model build

module load py-neurodamus

# Set the expected output message from the SHM file transfer
SHM_OUTPUT_MESSAGE="SHM file transfer mode for CoreNEURON enabled"

# Test the default execution with Neurodamus-py and SHM file transfer enabled
mkdir -p ${outputdir}
blue_set Simulator CORENEURON ${blueconfig}
RUN_PY_TESTS=yes SHM_ENABLED=ON run_simulation ${blueconfig} | tee "${outputdir}/sim.log"
test_check_results "${outputdir}" "${REF_RESULTS["quick-v5-plasticity"]}"
grep "${SHM_OUTPUT_MESSAGE}" "${outputdir}/sim.log" 1>/dev/null && log_ok "${SHM_OUTPUT_MESSAGE}"

# Test the multicycle execution with Neurodamus-py and SHM file transfer enabled
mkdir -p ${outputdir}_multi
cp "$blueconfig" "${blueconfig}_multi"
blue_set ModelBuildingSteps 2 ${blueconfig}_multi  # Build the model for CoreNeuron in 2 steps
blue_set OutputRoot "${outputdir}_multi" ${blueconfig}_multi
RUN_PY_TESTS=yes SHM_ENABLED=ON run_simulation ${blueconfig}_multi | tee "${outputdir}_multi/sim.log"
test_check_results "${outputdir}_multi" "${REF_RESULTS["quick-v5-plasticity"]}"
grep "${SHM_OUTPUT_MESSAGE}" "${outputdir}_multi/sim.log" 1>/dev/null && log_ok "${SHM_OUTPUT_MESSAGE}"
