#!/bin/bash
[ $ENVUTILS_LOADED ] || source "${BASH_SOURCE%/*}/envutils.sh"

log "Loading test definitions..."

# defaults
RUN_PY_TESTS="${RUN_PY_TESTS:-no}"
BLUECONFIG_DIR=`pwd`
DATADIR="${DATADIR:-/gpfs/bbp.cscs.ch/project/proj12/jenkins}"
EXTENDED_RESULTS="$DATADIR/cellular"

declare -A REF_RESULTS
REF_RESULTS["scx-v5"]="$EXTENDED_RESULTS/circuit-scx-v5/simulation"
REF_RESULTS["scx-v6"]="$EXTENDED_RESULTS/circuit-scx-v6/simulation"
REF_RESULTS["scx-1k-v5"]="$EXTENDED_RESULTS/circuit-1k/simulation"
REF_RESULTS["scx-1k-v5-newparams"]="$EXTENDED_RESULTS/circuit-1k/simulation-newparams"
REF_RESULTS["scx-2k-v6"]="$EXTENDED_RESULTS/circuit-2k/simulation"
REF_RESULTS["scx-v5-gapjunctions"]="$EXTENDED_RESULTS/circuit-scx-v5-gapjunctions/simulation"
REF_RESULTS["scx-v5-bonus-minis"]="$EXTENDED_RESULTS/circuit-scx-v5-bonus-minis/simulation"
REF_RESULTS["scx-v5-plasticity"]="$EXTENDED_RESULTS/circuit-scx-v5-plasticity/simulation"
REF_RESULTS["hip-v6"]="$EXTENDED_RESULTS/circuit-hip-v6/simulation"
REF_RESULTS["hip-v6-mcr4"]="$EXTENDED_RESULTS/circuit-hip-v6/simulation-mcr4"
REF_RESULTS["thalamus"]="$EXTENDED_RESULTS/circuit-thalamus/simulation"
REF_RESULTS["mousify"]="$EXTENDED_RESULTS/circuit-mousify/simulation"
REF_RESULTS["quick-v5-gaps"]="$EXTENDED_RESULTS/circuit-scx-v5-gapjunctions/simulation_quick"
REF_RESULTS["quick-v6"]="$EXTENDED_RESULTS/circuit-2k/simulation_quick"
REF_RESULTS["quick-v5-multisplit"]="$EXTENDED_RESULTS/circuit-v5-multisplit/simulation"
REF_RESULTS["quick-v5-plasticity"]="$EXTENDED_RESULTS/circuit-scx-v5-plasticity/simulation-quick"
REF_RESULTS["quick-hip-sonata"]="$EXTENDED_RESULTS/circuit-hip-v6/simulation-quick-sonata"
REF_RESULTS["quick-hip-projSeed"]="$EXTENDED_RESULTS/circuit-hip-v6/simulation-quick-projSeed"
REF_RESULTS["quick-hip-delayconn"]="$EXTENDED_RESULTS/circuit-hip-v6/simulation-quick-delayconn"
REF_RESULTS["quick-hip-multipopulation"]="$EXTENDED_RESULTS/circuit-hip-mooc/simulation-multipopulation"
REF_RESULTS["quick-mousify-sonata"]="$EXTENDED_RESULTS/circuit-n34-mousify/simulation"

_prepare_test() {
    # If test not provided check if curdir has BlueConfig
    if [ -z "$testname" ]; then
        if [[ -f BlueConfig && -f out.sorted ]]; then
            testname="${PWD##*/}"
        else
            log_error  "Test name not provided and not found in cur dir"
            exit -1
        fi
    else
        cd $BLUECONFIG_DIR/$testname
    fi

    log "[TEST SETUP] $testname from $PWD"

    # If neurodamus spec not given, check cur loaded
    if [ -z "$spec" ]; then
        spec=default
        which special # Ensure available
    fi

    # To run in parallel output and BlueConfig must be unique
    hash=$(echo "$spec" | md5sum | cut -c 1-8)
    log "Base Blueconfig copy: BlueConfig_$hash"
    cp BlueConfig "BlueConfig_$hash"

    configsrc=("BlueConfig_$hash")
    declare -gA blueconfigs
    declare -gA outputs
    blueconfigs["BlueConfig_$hash"]="BlueConfig_$hash"  # Default

    # to support running both HOC and PY tests and keep backward compatibility
    # we introduce RUN_HOC_TESTS. When not defined the meaning is the old one, i.e.
    # RUN_PY_TESTS defines which test to run. Otherwise, variables only control their test
    if [[ $RUN_HOC_TESTS == yes && $RUN_PY_TESTS == yes ]]; then
        # Create an additional blueconfig for a separate hoc execution
        cp BlueConfig "BlueConfig_hoc_$hash"
        configsrc+=( "BlueConfig_hoc_$hash" )
        blueconfigs["BlueConfig_hoc_$hash"]="BlueConfig_hoc_$hash"
    fi

    # Try find test_*.sh scripts, which can do all sort of stuff and launch the sim
    # This is specially required for save-resume simulation tests
    for bc_script in test_*.sh; do
        [ -f $bc_script ] || break  # bash will take it literally when does not exist
        bc_copy="BlueConfig_${bc_script:5:-3}_$hash"
        log "BlueConfig copy for script $bc_script: $bc_copy"
        cp BlueConfig $bc_copy
        configsrc+=( "$bc_script" )
        blueconfigs[$bc_script]=$bc_copy
    done

    # Patch all Blueconfigs, clean exisiting res
    log "Patching BlueConfigs OutputRoot..."
    for src in ${configsrc[@]}; do
        bc=${blueconfigs[$src]}
        suffix=${bc:11}
        _output=output_$suffix
        sed -i "s#OutputRoot.*#OutputRoot $_output#" $bc
        outputs["$src"]=$_output
        rm -rf $_output
    done

    if [ "$DRY_RUN" ]; then
        log "[SKIP] DRY-RUN test $testname ($spec) #$hash."
        return
    fi
    log "[TEST RUN] Launching test $testname ($spec) #$hash"

    # load env modules
    # ----------------

    local _tsetbk=$-
    set +x  # Never trace for module load

    if [ "$spec" != "default" ]; then
        log "COMMANDS: module purge; spack load $spec" "DBG"
        module purge
        if [ $RUN_PY_TESTS = "yes" ]; then
            log "Loading python with deps"
            module load py-neurodamus
        fi
        spack load $spec
    fi
    module list
    module list -t 2>&1 | grep neurodamus | while read mod; do module show "$mod"; done
    # Loading bluepy for the libsonata readers
    module load unstable py-bluepy

    set -$_tsetbk  # reenable disabled flags
}


test_check_results() (
    set -e
    output=$1
    ref_results=${2:-${REF_RESULTS[$(basename "$PWD")]}}
    ref_spikes=${3:-out.sorted}
    # Print nice msg on error
    trap "(set +x; log_error \"Results DON'T Match\n\"; exit 1)" ERR

    if [ "$DRY_RUN" ]; then
        return
    fi

    [ -f $output/spikes.dat ] && mv $output/spikes.dat $output/out.dat
    # Core neuron doesnt have a /scatter (!?)
    grep '/scatter' $output/out.dat > /dev/null || sed -i '1s#^#/scatter\n#' $output/out.dat
    sort -n -k'1,1' -k2 < $output/out.dat | awk 'NR==1 { print; next } { printf "%.3f\t%d\n", $1, $2 }' > $output/out.sorted
    (set -x; diff -wy --suppress-common-lines $ref_spikes $output/out.sorted)

    if [ -f $output/out_SONATA.dat ]; then
        grep '/scatter' $output/out_SONATA.dat > /dev/null || sed -i '1s#^#/scatter\n#' $output/out_SONATA.dat
        (set -x; diff -wy --suppress-common-lines $ref_spikes $output/out_SONATA.dat)
    elif [ -f $output/out.h5 ]; then
        (set -x; python "$_THISDIR/generate_sonata_out.py" "$output/out.h5")
        mv 'out_SONATA.dat' $output
        grep '/scatter' $output/out_SONATA.dat > /dev/null || sed -i '1s#^#/scatter\n#' $output/out_SONATA.dat
        (set -x; diff -wy --suppress-common-lines $ref_spikes $output/out_SONATA.dat)
    fi

    # compare reports
    for report in $(cd $output && ls *.bbp); do
        (set -x; cmp "$ref_results/$report" "$output/$report")
    done
    for sonata_report in $(cd $output && ls *.h5); do
        if [ "$sonata_report" != "out.h5" ]; then
            (set -x; [ -s $output/$sonata_report ] )
            (set -x; python "$_THISDIR/compare_sonata_reports.py" "$ref_results/$sonata_report" "$output/$sonata_report")
        fi
    done
    log_ok "Results Match"
)


check_prints(){
  [ "$DRY_RUN" ] && return 0
  set +x
  local expected="$1"
  local stopper="$2"
  local line
  local ret=1
  while read line; do
      echo "$line"
      if [[ "$line" =~ "$expected" ]]; then ret=0; fi
      if [ "$stopper" ] && [[ "$line" =~ "$stopper" ]]; then break; fi
  done
  return $ret
}


#
# Main function to start a test given its directory name.
# _prepare_test will additionally search for test_*.sh files and call them with a copy
#     of BlueConfig. Tests are then ran in parallel
#
# @param testname : The directory name containing the test, from the suite
# @param spec : the neurodamus spack version to be loaded (unique spec)
#
run_test() (
    set -e
    testname=$1
    spec="$2"

    (set +x; log
     log "------------ TEST: $testname ------------"
     log "spec: $spec"
    )

    # Will set $blueconfigs and an $output associate array
    _prepare_test

    # Single BlueConfig will run directly in foreground
    if [ ${#configsrc[@]} -eq 1 ]; then
        run_blueconfig $configsrc
        if [ -f "${outputs[$configsrc]}/.exception.expected" ]; then
            log "Expected exception detected"
        else
            test_check_results "${outputs[$configsrc]}" "${REF_RESULTS[$testname]}"
        fi
    else
        # Otherwise we launch several processes to the background, store output and wait
        # Loop over $blueconfig tests
        declare -A pids
        for src in ${configsrc[@]}; do
            log "Starting simulation from $src in parallel"
            configfile=${blueconfigs[$src]}

            # When using test scripts, handle DRY_RUN
            if [ ${src:(-3)} = .sh ]; then
                if [ "$DRY_RUN" ]; then
                    head ./$src > _$src.log &
                else
                    (source ./$src $configfile ${outputs[$src]}) &> _$src.log &
                fi
            else
                # run_blueconfig understands $DRY_RUN
                run_blueconfig $configfile &> _$src.log &
            fi
            pids[$src]=$!
        done

        sleep $([ "$DRY_RUN" ] && echo 1 || echo 10)  # Some time to have salloc info
        for src in ${configsrc[@]}; do
            log "Simulation $src status:"
            grep 'salloc:' _$src.log | sed 's/^/    /'
        done

        # Run checks in fg
        ERR=
        echo
        for src in ${configsrc[@]}; do
           log "Waiting for simulation $src results..."
            wait ${pids[$src]} || {
                log_error "Failed to run simulation. Log:"; cat _$src.log; ERR=y
                continue
            }

            log "Finished. Simulation log:"; cat _$src.log

            # Inner -e is not respected if we have '||'. We need to check $?
            set +e
            log "Checking results..."
            if [[ -f ${outputs[$src]}/.exception.expected ]]; then
                log "Expected exception detected"
            else
                unset REF_SPIKES
                if [[ -f ${outputs[$src]}/ref_spikes.txt ]]; then
                    REF_SPIKES=$(cat ${outputs[$src]}/ref_spikes.txt)
                fi
                test_check_results "${outputs[$src]}" "${REF_RESULTS[$testname]}" "${REF_SPIKES}"
                [ $? -eq 0 ] || ERR=y
            fi
            set -e
        done

        if [ $ERR ]; then
            log_error "Tests $testname failed\n"
            return 1
        fi
    fi

    log_ok "Tests $testname successfull\n" "PASS"
)

#
# Alternative function to start, in debug mode, a test given its directory name.
# Simiar to start_test() except it will enable bash -x and run sub-tests sequentially
#
run_test_debug() (
    set -xe
    testname=$1
    spec="$2"
    export OMP_NUM_THREADS=1

    # Will set $blueconfigs and an $output associate array
    _prepare_test

    for src in ${configsrc[@]}; do
        log "Starting simulation from $src"
        configfile=${blueconfigs[$src]}

        # When using test scripts
        if [ ${src:(-3)} = .sh ]; then
            (source ./$src $configfile ${outputs[$src]})
        else
            run_blueconfig $configfile
        fi
        test_check_results "${outputs[$src]}" "${REF_RESULTS[$testname]}"
    done
    log_ok "Tests $testname successfull\n" "PASS"
)


#
# Run neurodmus directly on a given blueconfig
#
# @param configFile: (optional) The BlueConfig for the simulation
#
run_blueconfig() (
    set -e
    configfile=${1:-"BlueConfig"}
    testname=${testname:-$(basename $PWD)}
    shift

    # If the blueconfig starts with BlueConfig_hoc and RUN_HOC_TESTS is yes then
    # we will run this test with HOC, independently of RUN_PY_TESTS
    if [[ $RUN_HOC_TESTS == yes && $configfile == BlueConfig_hoc* ]]; then
        RUN_PY_TESTS=no
    fi

    if [ $RUN_PY_TESTS == "yes" ]; then
        if [ -z "$NEURODAMUS_PYTHON" ] && [ -z "$DRY_RUN" ]; then
            log_error "NEURODAMUS_PYTHON var is not set. Unknown location of init.py"
            return 1
        fi
        INIT_ARGS=("-mpi" "-python" "$NEURODAMUS_PYTHON/init.py" "--configFile=$configfile" --verbose "$@")
    else
        # Check if Hoc supports
        for value in ${PY_ONLY_TESTS[@]}; do
            if [[ $value = $testname ]]; then
                log_warn "[SKIP] TEST $testname is only supported by neurodamus-py"
                # if called from run_test it will have outputs[$src] defined
                if [ "${outputs[$src]}" ]; then
                    mkdir -p "${outputs[$src]}"
                    touch "${outputs[$src]}/.exception.expected"
                fi
                return 0
            fi
        done

        INIT_ARGS=("-c" "{strdef configFile configFile=\"$configfile\"}" -mpi "$HOC_LIBRARY_PATH/init.hoc" "$@")
    fi

    N=${N:-$(set -x; [[ $testname =~ quick* ]] && echo 1 || echo 2)} \
    bb5_run special "${INIT_ARGS[@]}"
)

#
# Run a test script. It will also read the BlueConfig to get the OutputRoot
# and test it with test_check_results
#
# @param configFile: (optional) The BlueConfig for the simulation
#
run_test_script() (
    set -e
    [ "$1" ] || (log_error "Please provide a test script" && return 1)
    script_file="$1"
    configfile=${2:-"BlueConfig"}
    output_root=$(blue_get OutputRoot $configfile)

    # Run by sourcing in subshell (Whatever is defined can be discarded)
    (. $script_file $configfile $output_root)

    test_check_results $output_root
)


#
# Launches a debug neurodamus session, using '_debug.[hoc/py]'
#
run_debug() (
    set -e
    testname=$1
    spec="$2"
    _prepare_test

    bb5_run special $HOC_LIBRARY_PATH/_debug.hoc -mpi

    # compare nrndat
    for nrnfile in *.nrndat; do
        (set -x
         diff -wy --suppress-common-lines expected_nrndat/$nrnfile $nrnfile)
    done
)


# HELPERS
# =======

run_all_tests() (
    (set +x; echo """
=====================================================================
Running tests (DRY="$DRY_RUN")
=====================================================================
""")
    set -e
    unset spec
    which special &> /dev/null || LOAD_SPEC=1
    for version in $TEST_VERSIONS; do
        [ $LOAD_SPEC ] && spec="${VERSIONS[$version]}"
        for testname in ${TESTS[$version]}; do
            run_test $testname "$spec"
        done
    done
)


run_quick_tests() (
    set -e
    _VERSIONS_BK=$TEST_VERSIONS
    _TESTS_NCX=${TESTS[neocortex]}
    _TESTS_NCX_PLAST=${TESTS[ncx_plasticity]}
    TEST_VERSIONS="ncx_bare neocortex ncx_plasticity"
    TESTS[neocortex]=${TESTS[ncx_bare]}
    TESTS[ncx_plasticity]="quick-v5-plasticity"

    run_all_tests

    TEST_VERSIONS=$_VERSIONS_BK
    TESTS[neocortex]=_TESTS_NCX
    TESTS[ncx_plasticity]=_TESTS_NCX_PLAST
)


# Prepare env for running tests
# -----------------------------
if [ -z $SPACK_ROOT ]; then
    log_warn "No SPACK_ROOT. Please setup spack before launching tests. Consider sourcing '.tests_setup.sh' instead"
    return 1
fi

set +x
source $SPACK_ROOT/share/spack/setup-env.sh
log_ok "Tests ready"

if [ ! $BASH_TRACE ]; then
    set -$_setbk
elif [ $BASH_TRACE = yes ]; then
    set -x
fi
