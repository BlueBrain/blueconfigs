#!/bin/bash
source ../toolbox.sh
configfile_bk $1

# This test file checks the new default of removing coreneuron files by default
# and the possibility of overriding such default with BlueConfig or --keep-build (Python)
#
# 4 Scenarios (all using coreneuron):
#   1. Hoc version. data will be deleted
#   2. Neurodamus-py. Idem
#   3. neurodamuspy --keep-data. No deletion
#   4. Hoc version, Blueconfig setting keepModelData=True. No deletion

outputdir=${2:-output}
coreneuron_data=$outputdir/coreneuron_input

#######################################################

echo ">> Test CoreNeuron data removal with neurodamus (hoc)"
blue_set Simulator CORENEURON $blueconfig
run_blueconfig $blueconfig

if [ -d "$coreneuron_data" ]; then
    log_error "$coreneuron_data should be deleted by default"
    exit -1
fi

rm -rf "$outputdir"

#######################################################

echo ">> Test CoreNeuron data removal with neurodamus-py"
module load py-neurodamus
RUN_PY_TESTS=yes run_blueconfig $blueconfig

if [ -d "$coreneuron_data" ]; then
    log_error  "$coreneuron_data should be deleted by default"
    exit -1
fi

rm -rf "$outputdir"

#######################################################

echo ">> Test CoreNeuron data preserve with neurodamus-py --keep-build"
RUN_PY_TESTS=yes run_blueconfig $blueconfig "--keep-build"

# Check if intermediate data is kept after run
if [ -d "$coreneuron_data" ]; then
    echo "Check CORENEURON intermediate data kept by demand: OK"
else
    log_error "coreneuron_data ($coreneuron_data) was not kept"
    exit -1
fi

rm -rf "$outputdir"

#######################################################

echo ">> Test CoreNeuron data preserve with neurodamus(Hoc) BueConfig keepModelData"
blue_set keepModelData True $blueconfig
run_blueconfig $blueconfig

# Check if intermediate data is kept after run
if [ -d $coreneuron_data ]; then
    echo "Check CORENEURON intermediate data kept by demand: OK"
else
    log_error "$coreneuron_data was not kept"
    exit -1
fi

