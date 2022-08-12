#!/bin/bash
set -e
source ../toolbox.sh
configfile_bk "$1"

outputdir="${2:-output}"

export OMP_NUM_THREADS=1

# Test two scenarios using neurodamus-py:
#  - SHM file transfer on a single pass
#  - SHM file transfer with multicycle model build

module load py-neurodamus py-bluepy

# Test the default execution with Neurodamus-py and SHM file transfer enabled
blue_set Simulator CORENEURON ${blueconfig}
RUN_PY_TESTS=yes run_blueconfig ${blueconfig} "--enable-shm"
test_check_results "${outputdir}" "${REF_RESULTS["quick-v5-plasticity"]}"

# Test the multicycle execution with Neurodamus-py and SHM file transfer enabled
cp "$blueconfig" "${blueconfig}_multi"
blue_set ModelBuildingSteps 2 ${blueconfig}_multi  # Build the model for CoreNeuron in 2 steps
blue_set OutputRoot "${outputdir}_multi" ${blueconfig}_multi
RUN_PY_TESTS=yes run_blueconfig ${blueconfig}_multi "--enable-shm"
test_check_results "${outputdir}_multi" "${REF_RESULTS["quick-v5-plasticity"]}"
