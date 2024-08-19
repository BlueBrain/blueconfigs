#!/usr/bin/bash
set -e
outputdir="$2"

# Named _sim_config.json so it's not picked up by the framework
python3 run_neurodamus_axon.py _sim_config.json

mkdir -p "$outputdir"
touch "$outputdir/.test_check_results.skip"
