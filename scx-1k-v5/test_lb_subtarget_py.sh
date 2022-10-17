#!/bin/sh

# Test several scenarios of load_balance
# NOTE: We must be careful with concurrent tests since cx files are
# all created in pwd. At most one test should do load bal

source ../toolbox.sh
configfile_bk $1
outputdir="${2:-output}"
# Set to run with Python if not defined
export RUN_PY_TESTS=yes

blue_set RunMode WholeCell $blueconfig
blue_set Duration 2 $blueconfig
blue_comment_section Report $blueconfig

echo "
>> Setting Target to MiniColumn_1"
rm -rf sim_conf/cx* sim_conf/_loadbal_* mcomplex.dat
blue_set CircuitTarget MiniColumn_1 $blueconfig
run_blueconfig $blueconfig | check_prints "Could not reuse load balance data" "INSTANTIATING"

echo "
>> Setting Target to Small. Must reuse info from any previous"
blue_set CircuitTarget Small $blueconfig
N=1 run_blueconfig $blueconfig | check_prints "Target Small is a subset of the target" "INSTANTIATING"

#skip result check
mkdir -p "$outputdir"
touch "$outputdir/.exception.expected"
