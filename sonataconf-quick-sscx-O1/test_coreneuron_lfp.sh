#!/bin/sh
source ../toolbox.sh
echo $1
sonata_configfile_bk $1

sonataconf_set "target_simulator" "CORENEURON" "$sonataconfig"
update_simconf $sonataconfig "run" "electrodes_file" "${REF_RESULTS["sonataconf-quick-sscx-O1"]}/coeffs.h5"
update_simconf $sonataconfig "reports" "lfp_report" '{"cells": "All", "sections": "all", "type": "lfp", "variable_name": "v", "unit": "mV", "dt": 0.1, "start_time": 0.0, "end_time": 100.0}'
echo "Run CORENEURON lfp with $sonataconfig"
run_simulation $sonataconfig
