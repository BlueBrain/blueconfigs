#!/bin/bash
source ../toolbox.sh
configfile_bk $1

echo ">> Test with CORENEURON simulator by default"
blue_set Simulator CORENEURON $blueconfig
RUN_PY_TESTS=yes run_blueconfig $blueconfig

# Check if intermediate data is deleted by default
outputdir=$2
coreneuron_data=$outputdir/coreneuron_input
if [ -d $coreneuron_data ]; then
    log_error  "$coreneuron_data should be deleted by default"
    exit -1
else
    echo "Check CORENEURON intermediate data by default : OK"
fi

echo ">> Test with CORENEURON simulator and keep intermediate data"
blue_set keepModelData True $blueconfig
RUN_PY_TESTS=yes run_blueconfig $blueconfig

# Check if intermediate data is kept after run
if [ -d $coreneuron_data ]; then
    echo "Check CORENEURON intermediate data kept by demand: OK"
else
    log_error  "$coreneuron_data is not kept"
    exit -1
fi
