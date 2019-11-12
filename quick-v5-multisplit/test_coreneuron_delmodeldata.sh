#!/bin/bash
source ../toolbox.sh
configfile_bk $1

echo ">> Test with CORENEURON simulator"
blue_set Simulator CORENEURON $blueconfig
run_blueconfig $blueconfig

# Check if intermediate data exists by default
outputdir=$2
coreneuron_data=$outputdir/coreneuron_input
if [ -d $coreneuron_data ]; then
    echo "Check CORENEURON intermediate data by default : OK"
else
    log_error  "$coreneuron_data should not be deleted by default"
    exit -1
fi

echo ">> Test with CORENEURON simulator and delete intermediate data"
blue_set keepModelData False $blueconfig
run_blueconfig $blueconfig

# Check if intermediate data is deleted after run
if [ -d $coreneuron_data ]; then
    log_error  "$coreneuron_data is not deleted"
    exit -1
else
    echo "Check CORENEURON intermediate data deletion : $coreneuron_data is deleted"
fi
