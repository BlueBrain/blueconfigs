#!/bin/sh

# Test several scenarios of load_balance
# NOTE: We must be careful with concurrent tests since cx files are
# all created in pwd. At most one test should do load bal

module load py-neurodamus
module list

source ../toolbox.sh
configfile_bk $1
outputdir="${2:-output}"
# Set to run with Python if not defined
export RUN_PY_TESTS=yes

blue_set RunMode WholeCell $blueconfig
blue_set Duration 10 $blueconfig

echo "
>> Setting Target to MiniColumn_1"
rm -rf sim_conf/cx* mcomplex.dat
blue_set CircuitTarget MiniColumn_1 $blueconfig
run_blueconfig $blueconfig | check_prints "Could not reuse load balance data" "INSTANTIATING"

echo "
>> Unsetting Target in $blueconfig. Wont be able to resume"
blue_comment CircuitTarget $blueconfig
run_blueconfig $blueconfig | check_prints "Could not reuse load balance data" "INSTANTIATING"

echo "
>> Setting Target to Small. Must reuse info from any previous"
blue_set CircuitTarget Small $blueconfig
run_blueconfig $blueconfig | check_prints "Target Small is a subset of the target" "INSTANTIATING"

# With multi-split and Prospective hosts
echo "
>> Recreating loadBalance info for target Small with MultiSplit and ProspectiveHosts"
blue_set RunMode LoadBalance $blueconfig
blue_set ProspectiveHosts 50 $blueconfig
rm -rf sim_conf/cx*
run_blueconfig $blueconfig | check_prints "at least one cell is broken into" "INSTANTIATING"

echo "
>> Setting target to verySmall, should reuse multisplit LoadBal"
blue_set CircuitTarget verySmall $blueconfig
run_blueconfig $blueconfig | check_prints "at least one cell is broken into" "INSTANTIATING"

#skip result check
touch $outputdir/.exception.expected

