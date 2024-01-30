#!/bin/bash
[ $ENVUTILS_LOADED ] || source "${BASH_SOURCE%/*}/envutils.sh"
source "${BASH_SOURCE%/*}/../toolbox.sh"

BASE_DIR=`pwd`
RUN_PY_TESTS="${RUN_PY_TESTS:-no}"
declare -A REF_RESULTS_LONGRUN
REF_RESULTS_LONGRUN["scx-v5-plasticity"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-scx-v5-plasticity/simulation-long"
REF_RESULTS_LONGRUN["quick-hip-multipopulation"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-hip-mooc/simulation-long"
REF_RESULTS_LONGRUN["mousify"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-mousify/simulation-long"
REF_RESULTS_LONGRUN["thalamus"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-thalamus/simulation-long"
REF_RESULTS_LONGRUN["sonataconf-thalamus"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-thalamus/simulation-sonataconf-long"
REF_RESULTS_LONGRUN["sonataconf-hippocampus"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-hip-sonata/simulation-sonataconf-long"
REF_RESULTS_LONGRUN["sonataconf-sscx-O1"]="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-sscx-O1/simulation-long"


run_long_test() (
    set -e
    testname=$1
    spec="$2"
    target="$3"
    configfile="simulation_config_longrun.json"
    outputdir="output_coreneuron_longrun"
    (set +x; log
     log "------------ LONG TEST: $testname ------------"
     log "spec: $spec"
     log "target: $target"
    )

    # prepare test
    cd "$BASE_DIR/$testname"
    prepare_sonataconfig $configfile $outputdir $target

    set +x
    head -n 40 "$configfile"

    log "Launching test $testname ($spec)"

    set -e
    # If neurodamus spec not given, check loaded
    if [ -z "$spec" ]; then
        spec=default
        which special # Ensure available
    else
        echo "COMMANDS: module purge; spack load $spec" "DBG"
        module purge
        if [ $RUN_PY_TESTS = "yes" ]; then
            echo "Loading python with deps"
            module load py-neurodamus
        fi
        spack load $spec
        log "COMMANDS: module load py-libsonata-mpi; export ROMIO_PRINT_HINTS=1" "DBG"
        module load py-libsonata-mpi
        export ROMIO_PRINT_HINTS=1
    fi
    module list
    module list -t 2>&1 | grep neurodamus | while read mod; do module show "$mod"; done
    module load unstable py-bluepy  # req. for the libsonata readers
    set +e

    nodes=64
    if [ $testname = "thalamus" ]; then
        nodes=16  # thalamus cell count is slightly lower and mods are really fast
    fi
    SALLOC_PARTITION=prod N=${nodes} n=$(expr "$nodes" '*' 40) run_simulation "$configfile" --lb-mode=WholeCell
    test_check_results "$outputdir" "${REF_RESULTS_LONGRUN[$testname]}" "${REF_RESULTS_LONGRUN[$testname]}/out.h5"

)

prepare_sonataconfig() (
    configfile=$1
    outputdir=$2
    target=$3
    cp simulation_config.json $configfile
    python $_THISDIR/update_simconf_longrun.py $configfile $outputdir $target
)
