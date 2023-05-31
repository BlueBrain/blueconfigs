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
REF_RESULTS["scx-v6"]="$EXTENDED_RESULTS/circuit-scx-v6/simulation_v2"
REF_RESULTS["scx-1k-v5"]="$EXTENDED_RESULTS/circuit-1k/simulation_v2"
REF_RESULTS["scx-1k-v5-newparams"]="$EXTENDED_RESULTS/circuit-1k/simulation-newparams_v1"
REF_RESULTS["scx-2k-v6"]="$EXTENDED_RESULTS/circuit-2k/simulation_v2"
REF_RESULTS["scx-v5-gapjunctions"]="$EXTENDED_RESULTS/circuit-scx-v5-gapjunctions/simulation_v4"
REF_RESULTS["scx-v5-bonus-minis"]="$EXTENDED_RESULTS/circuit-scx-v5-bonus-minis/simulation_v1"
REF_RESULTS["scx-v5-plasticity"]="$EXTENDED_RESULTS/circuit-scx-v5-plasticity/simulation_v3"
REF_RESULTS["hip-v6"]="$EXTENDED_RESULTS/circuit-hip-v6/simulation_v2"
REF_RESULTS["hip-v6-mcr4"]="$EXTENDED_RESULTS/circuit-hip-v6/simulation-mcr4"
REF_RESULTS["thalamus"]="$EXTENDED_RESULTS/circuit-thalamus/simulation_v1"
REF_RESULTS["mousify"]="$EXTENDED_RESULTS/circuit-mousify/simulation_v1"
REF_RESULTS["quick-v5-gaps"]="$EXTENDED_RESULTS/circuit-scx-v5-gapjunctions/simulation_quick_v1"
REF_RESULTS["quick-v6"]="$EXTENDED_RESULTS/circuit-2k/simulation_quick_v1"
REF_RESULTS["quick-v5-multisplit"]="$EXTENDED_RESULTS/circuit-v5-multisplit/simulation_v1"
REF_RESULTS["quick-v5-plasticity"]="$EXTENDED_RESULTS/circuit-scx-v5-plasticity/simulation-quick_v3"
REF_RESULTS["quick-v7-plasticity"]="$EXTENDED_RESULTS/circuit-sscx-v7-plasticity/simulation-quick_v1"
REF_RESULTS["quick-hip-sonata"]="$EXTENDED_RESULTS/circuit-hip-v6/simulation-quick-sonata"
REF_RESULTS["quick-hip-projSeed2"]="$EXTENDED_RESULTS/circuit-hip-v6/simulation-quick-projSeed2"
REF_RESULTS["quick-hip-delayconn"]="$EXTENDED_RESULTS/circuit-hip-v6/simulation-quick-delayconn"
REF_RESULTS["quick-hip-multipopulation"]="$EXTENDED_RESULTS/circuit-hip-mooc/simulation-multipopulation"
REF_RESULTS["quick-mousify-sonata"]="$EXTENDED_RESULTS/circuit-n34-mousify/simulation"
REF_RESULTS["quick-1k-v5-nodesets"]="$EXTENDED_RESULTS/circuit-1k/simulation-quick-nodesets"
REF_RESULTS["sonataconf-quick-hip-multipopulation"]="$EXTENDED_RESULTS/circuit-hip-mooc/simulation-sonataconf"
REF_RESULTS["sonataconf-quick-v5-plasticity"]="$EXTENDED_RESULTS/circuit-scx-v5-plasticity/simulation-quick-sonataconf"
REF_RESULTS["sonataconf-quick-scx-multi-circuit"]="$EXTENDED_RESULTS/circuit-scx-multicircuit/simulation-sonataconf_v1"
REF_RESULTS["sonataconf-quick-ngv-usecase5"]="$EXTENDED_RESULTS/circuit-ngv-usecase5/simulation-sonataconf"
REF_RESULTS["sonataconf-quick-thalamus"]="$EXTENDED_RESULTS/circuit-thalamus/simulation-sonataconf_v3"
REF_RESULTS["multiscale"]="$DATADIR/subcellular/blueconfigs_test/reference_files"
REF_RESULTS["sonataconf-quick-multiscale"]="$DATADIR/subcellular/blueconfigs_test/simulation-sonataconf/reference_files"

_prepare_test() {
    confFile="${1:-BlueConfig}" #either sonata config or BlueConfig
    # If test not provided check if curdir has BlueConfig
    if [ -z "$testname" ]; then
        if [ -f $confFile ] && [ -f "out.sorted" ]; then
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

    declare -gA blueconfigs
    declare -gA outputs

    hash=$(echo "$spec" | md5sum | cut -c 1-8)
    # Check if there is a default BlueConfig
    if [ -f $confFile ]; then
        # To run in parallel output and BlueConfig must be unique
        if [[ ${confFile} == *json ]] ; then
            confFile_copy=${confFile%".json"}"_"$hash".json"
        else
            confFile_copy=$confFile"_"$hash
        fi
        log "Base $confFile file copy: $confFile_copy"
        cp $confFile $confFile_copy

        configsrc=("$confFile_copy")
        blueconfigs["$confFile_copy"]="$confFile_copy"  # Default
    else
        log_warn "Base $confFile file not found"
    fi

    # to support running both HOC and PY tests and keep backward compatibility
    # we introduce RUN_HOC_TESTS. When not defined the meaning is the old one, i.e.
    # RUN_PY_TESTS defines which test to run. Otherwise, variables only control their test
    if [ "$RUN_HOC_TESTS" == "yes" ] && [ "$RUN_PY_TESTS" == "yes" ] && [ -f "$confFile" ]; then
        # Create an additional blueconfig for a separate hoc execution
        cp $confFile "BlueConfig_hoc_$hash"
        configsrc+=( "BlueConfig_hoc_$hash" )
        blueconfigs["BlueConfig_hoc_$hash"]="BlueConfig_hoc_$hash"
    fi

    # Try find test_*.sh scripts, which can do all sort of stuff and launch the sim
    # This is specially required for save-resume simulation tests
    for bc_script in test_*.sh; do
        [ -f $bc_script ] || break  # bash will take it literally when does not exist
        if [ -f "$confFile" ]; then
            if [[ $confFile == *json ]]; then
                bc_copy=${confFile%".json"}"_${bc_script:5:-3}_"$hash".json"
            else
                bc_copy=$confFile"_"${bc_script:5:-3}"_"$hash
            fi
            log "$confFile copy for script $bc_script: $bc_copy"
            cp $confFile $bc_copy
            configsrc+=( "$bc_script" )
            blueconfigs[$bc_script]=$bc_copy
        else
            configsrc+=( "$bc_script" )
            blueconfigs[$bc_script]="none"
        fi
    done

    # Patch all Blueconfigs, clean exisiting res
    log "Patching $confFile OutputRoot..."
    for src in ${configsrc[@]}; do
        bc=${blueconfigs[$src]}
        if [[ ${bc} == *json ]]; then
            suffix=${bc: 18: -5}
            _output=output_$suffix
            sonataconf_set "output_dir" "$_output" $bc
        else
            suffix="none"
            if [ ${bc} != "none" ]; then
                suffix=${bc:11}
            fi
            _output=output_$suffix
            if [ ${bc} != "none" ]; then
                blue_set "OutputRoot" "$_output" $bc
            fi
        fi
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
        set -e
        log "COMMANDS: module purge; spack load $spec" "DBG"
        module purge
        if [ $RUN_PY_TESTS = "yes" ]; then
            log "Loading python with deps"
            # olupton 2022-02-03: after BlueBrain/spack#1406 then models depend
            #   on py-neurodamus, but as this is not a run dependency the spack
            #   load command below is not sufficient.
            which neurodamus &> /dev/null || module load unstable py-neurodamus
        fi
        spack load $spec
        set +e
    fi
    module list
    module list -t 2>&1 | grep neurodamus | while read mod; do module show "$mod"; done
    # Loading bluepy for the libsonata readers
    # olupton 2022-02-02: this leaks a deployed NEURON version into the
    #   environment, let's load it when needed instead.
    # module load unstable py-bluepy
    set -$_tsetbk  # reenable disabled flags
}


check_spike_files() {
    local spike_file="$1"
    local ref_spikes="${2:-out.sorted}"
    local _output="$(dirname $1)"
    local _basename="$(basename $1)"
    # Some outputs (CoreNeuron) dont have a /scatter
    grep '/scatter' "$spike_file" > /dev/null || sed -i '1s#^#/scatter\n#' "$spike_file"
    # Sort Neuron output
    if [ "$_basename" = "out.dat" ]; then
        sort -n -k'1,1' -k2 < "$spike_file" | awk 'NR==1 { print; next } { printf "%.3f\t%d\n", $1, $2 }' > "$_output/out.sorted"
        spike_file="$_output/out.sorted"
    fi
    # We compare the spikes file
    # If the env variable UPDATE_REFERENCE_FILES is set to ON
    # then we update the reference spikes file with the one generated here
    # Spike reference files normally exist only in the repository so we have
    # to commit the changes then and create a MR to update them
    #
    # TODO: THIS DOESN'T WORK WELL FOR THE LONG TESTS. THOSE REFERENCE SPIKES COME FROM A `proj12` DIRECTORY AND HAVE NO GIT VERSIONING OR VERSIONING
    # TODO: WE HAVE TO FIGURE OUT A WAY TO VERSION THE SPIKE REPORTS FOR THE LONG TESTS OR AVOID AUTOMATIC UPDATES FOR SPIKES
    #
    (set -x; diff -wy --suppress-common-lines $ref_spikes $spike_file || if [[ $UPDATE_REFERENCE_FILES == "ON" ]]; then echo "Updating reference spikes $spike_file -> $ref_spikes"; cp $spike_file $ref_spikes; else false; fi;)
}


test_check_results() (
    set -e
    local output="$1"
    local ref_results=${2:-${REF_RESULTS[$(basename "$PWD")]}}
    local ref_spikes="${3:-out.sorted}"
    local fraction_sonata_report_compare="$4"
    if [ -z "$3" ] && [ -f "$output/ref_spikes.txt" ]; then
        ref_spikes=$(<"$output/ref_spikes.txt")
    fi
    # Print nice msg on error
    trap "(set +x; log_error \"Results DON'T Match\"; exit 1)" ERR SIGINT SIGTERM

    log "Checking results in $output"
    if [ "$DRY_RUN" ]; then
        log_ok "Results check skipped (dry run)"
        return
    fi
    if [ -f "$output/.exception.expected" ]; then
        log_ok "Expected exception detected"
        return
    fi

    # load libsonata now since its required for new comparison tools
    module load unstable py-libsonata python-dev

    if [[ $ref_spikes == *"out.h5" ]] && [ -f $ref_spikes ]; then
        (set -x; python "$_THISDIR/compare_sonata_spikes.py" \
                        "$output/out.h5" \
                        "$ref_spikes")
    else
        check_spike_files $output/out.dat "$ref_spikes"

        if [ -f $output/out_SONATA.dat ]; then
            check_spike_files $output/out_SONATA.dat "$ref_spikes"
        elif [ -f $output/out.h5 ]; then
            (set -x; python "$_THISDIR/generate_sonata_out.py" \
                            "$output/out.h5" \
                            "$output/out_SONATA.dat")
            check_spike_files $output/out_SONATA.dat "$ref_spikes"
        fi
    fi

    # compare reports
    if [[ "${output}" == *"coreneuron"* ]]; then
      coreneuron_suffix="_coreneuron"
    else
      coreneuron_suffix=""
    fi
    for sonata_report in $(cd $output && ls *.h5); do
        if [ "$sonata_report" != "out.h5" ]; then
            if [ ! -s $output/$sonata_report ]; then
                echo "Empty report file!"
                return 1
            fi
            nameroot=$(basename "${sonata_report}" .h5)
            arch_suffix="${coreneuron_suffix}_${BUILD_COMPILER}_${BUILD_COMPILER_VERSION}_${BUILD_TYPE}"
            expected_report_name="${nameroot}_v${REFERENCE_REPORTS_VERSION}${arch_suffix}.h5"
            ref_file="${ref_results}/${expected_report_name}"
            if [[ ! -f "${ref_file}" ]]; then
                # find file whose version is largest available but less than REFERENCE_REPORTS_VERSION
                largest_version_less_than_desired_version_filename=""
                # check whether any "${ref_results}/${nameroot}_v*[0-9]${arch_suffix}.h5" exist otherwise "versioned_files" cannot be set properly
                if ls ${ref_results}/${nameroot}_v*[0-9]${arch_suffix}.h5 1> /dev/null 2>&1; then
                    # all the versioned files
                    versioned_files=(${ref_results}/${nameroot}_v\[0-9\]*${arch_suffix}.h5)
                    # versions defined in the versioned files
                    versions=()
                    # find all the versions
                    for f in $versioned_files; do
                        versions+=($(echo $(basename -- $f) | grep -o "_v[0-9]*_" | grep -o "[0-9]*"))
                    done
                    # sort the versions
                    versions=($(echo ${versions[@]} | xargs -n1 | sort -g | xargs))
                    # find the largest versions which is less than the desired vesion
                    final_version=""
                    for v in "${versions[@]}"; do
                        if [ $v -lt ${REFERENCE_REPORTS_VERSION} ]; then
                            final_version=$v
                        else
                            break
                        fi
                    done
                    if [[ ! -z $final_version ]]; then
                        largest_version_less_than_desired_version_filename="${nameroot}_v${final_version}${arch_suffix}.h5"
                    fi
                fi
                # if there is a filename whose version is less than REFERENCE_REPORTS_VERSION set ref_file to it
                if [[ ! -z $largest_version_less_than_desired_version_filename ]]; then
                    ref_file="${ref_results}/${largest_version_less_than_desired_version_filename}"
                # else fall back to the file without <_v*> (fallback for reference files before version introduction)
                elif [[ -f "${ref_results}/${nameroot}${arch_suffix}.h5" ]]; then
                    ref_file="${ref_results}/${nameroot}${arch_suffix}.h5"
                # if it doesn't exist just use the plain <sonata_report> file (fallback for old reference files)
                else
                    ref_file="${ref_results}/${sonata_report}"
                fi
            fi
            # Compare the sonata reports
            # If the env variable UPDATE_REFERENCE_FILES is set to ON
            # then we update the reference files according to "${ref_results}/${arch_report}"
            # If a file with the expected name exists then avoid overriding it. If it needs to change then there should be a new version
            (set -x; python "$_THISDIR/compare_sonata_reports.py" \
                            "${ref_file}" \
                            "$output/$sonata_report" \
                            $fraction_sonata_report_compare || if [[ $UPDATE_REFERENCE_FILES == "ON" ]] && [[ ! -f "${ref_results}/${expected_report_name}" ]]; then echo "Updating reference files $output/$sonata_report -> ${ref_results}/${expected_report_name}"; cp $output/$sonata_report ${ref_results}/${expected_report_name}; else false; fi;)
        fi
    done
    log_ok "Results Match"
)


check_prints(){
  [ "$DRY_RUN" ] && return 0
  set +x
  local expected="$1"
  local stopper="$2"
  local line noprint
  local ret=1
  while read line; do
      [[ "$noprint" ]] || echo "$line"
      if [[ "$line" =~ "$expected" ]]; then ret=0; fi
      if [ "$stopper" ] && [[ "$line" =~ "$stopper" ]]; then noprint=1; fi
  done
  return $ret
}


# An semi-ugly workaround for bash not respecting -e in conditional clauses
_test_results() {
    set +e
    test_check_results "$@"
    [ $? -eq 0 ] || error_detected=y
    set -e
}


_kill_jobs() {
    log_error "Error detected! Cancelling simulations... Pids: $@"
    for i in $@; do
        { pkill -P $i; kill $i; } >& /dev/null || true
    done
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

    if [[ $testname == "sonataconf"* ]]; then
        confFile="simulation_config.json"
    else
        confFile="BlueConfig"
    fi

    # Will set $blueconfigs and an $output associate array
    _prepare_test $confFile

    # Single BlueConfig if it's the default will run directly in foreground
    if [ ${#configsrc[@]} -eq 1 ] && [ ${blueconfigs[$configsrc]} != "none" ]; then
        run_blueconfig "$configsrc"
        if [[ $configsrc == *json ]]; then
            test_check_results "${outputs[$configsrc]}" "${REF_RESULTS[$testname]}" "${REF_RESULTS[$testname]}/out.h5"
        else
            test_check_results "${outputs[$configsrc]}"
        fi
        log_ok "Tests $testname successful\n" "PASS"
        return 0
    fi

    # Otherwise we launch several processes to the background, store output and wait
    # Install a TRAP to properly clean up subprocesses on error
    trap '_kill_jobs ${pids[@]}' ERR SIGINT SIGTERM

    # Loop over $blueconfig tests
    declare -A pids
    declare baseconfig
    for src in ${configsrc[@]}; do
        log "Starting simulation from $src in parallel"
        configfile=${blueconfigs[$src]}

        # When using test scripts, handle DRY_RUN
        if [ ${src:(-3)} = .sh ]; then
            if [ "$DRY_RUN" ]; then
                log_warn "Would execute $src [Dry Run]" "SKIP" > _$src.log &
            else
                (   trap '_kill_jobs ${pids[@]}' ERR SIGINT SIGTERM
                    source ./$src "$configfile" "${outputs[$src]}"
                ) &> _$src.log &
            fi
            pids[$src]=$!
        else
            # For BlueConfig files, we only run in fg the first one
            if [ -z "$baseconfig" ]; then
                baseconfig="$src"
            else
                run_blueconfig "$configfile" &> _$src.log &
                pids[$src]=$!
            fi
        fi
    done

    log_ok "Done launching simulations for $testname. Waiting for results..."

    local error_detected=  # flag to mark error, so we print all results

    # Base one runs in foreground
    if [ -n "$baseconfig" ]; then
        echo; log "Base BlueConfig launch: $baseconfig"
        run_blueconfig "$baseconfig" # understands $DRY_RUN
        log "Simulation Finished: $baseconfig"
        if [[ $baseconfig == *json ]]; then
            _test_results "${outputs[$baseconfig]}" "${REF_RESULTS[$testname]}" "${REF_RESULTS[$testname]}/out.h5"
        else
            _test_results "${outputs[$baseconfig]}"
        fi
        echo  # newline
    fi

    for src in ${configsrc[@]}; do
        [ "${pids[$src]}" ] || continue
        log " ================ JOB $src ================="
        # Show tail
        tail -n20 _$src.log
        # Skip if some job failed
        [ -z "$error_detected" ] || { echo "Previous errors detected."; continue; }
        # Otherwise follow job
        tail -n0 -f _$src.log &
        tail_pid=$!
        wait ${pids[$src]} || {
            log_error "Failed to run simulation. FULL LOG:"; cat _$src.log;
            error_detected=y
            continue
        }
        log "Job Finished: $src"
        kill $tail_pid  # stop the corresponding tail process

        configfile=${blueconfigs[$src]}
        if [[ $configfile == *json ]]; then
            _test_results "${outputs[$src]}" "${REF_RESULTS[$testname]}" "${REF_RESULTS[$testname]}/out.h5"
        else
            _test_results "${outputs[$src]}"
        fi
        echo  # newline
    done

    if [ "$error_detected" ]; then
        log_error "Tests $testname failed\n"
        return 1
    fi
    log_ok "Tests $testname successful\n" "PASS"
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
            (source ./$src "$configfile" "${outputs[$src]}")
        else
            run_blueconfig "$configfile"
        fi
        test_check_results "${outputs[$src]}" "${REF_RESULTS[$testname]}"
    done
    log_ok "Tests $testname successful\n" "PASS"
)


#
# Run neurodmus directly on a given blueconfig
#
# @param configFile: (optional) The BlueConfig for the simulation
#
run_blueconfig() (
    set -e
    configfile=${1:-"BlueConfig"}
    if [[ $configfile == *json* ]] ; then
        outputdir=$(grep -o '"output_dir": "[^"]*' $configfile | grep -o '[^"]*$')
    else
        outputdir=$(blue_get OutputRoot $configfile)
    fi
    testname=${testname:-$(basename $PWD)}
    shift

    # If the blueconfig starts with BlueConfig_hoc we typically need to set RUN_PY_TESTS to 'no'
    # However, sometimes tests only run in neurodamus-py, so skip it
    if [[ $configfile == BlueConfig_hoc* ]]; then
        if _contains "${PY_ONLY_TESTS[@]}" "$testname"; then
            log_warn "[SKIP] No nd-py for explicit hoc run. Creating $outputdir/.exception.expected"
            mkdir -p "$outputdir" && touch "$outputdir/.exception.expected"
            return 0
        fi
        RUN_PY_TESTS=no
    fi

    # Check if Hoc supports. Otherwise need to run w neurodamus-py
    if [ "$RUN_PY_TESTS" != yes ] && _contains "${PY_ONLY_TESTS[@]}" "$testname"; then
        log "TEST $testname is only supported by neurodamus-py. Loading it"
        RUN_PY_TESTS=yes
        [ "$DRY_RUN" ] || module load py-neurodamus
    fi

    if [ "$RUN_PY_TESTS" == "yes" ]; then
        if [ -z "$NEURODAMUS_PYTHON" ] && [ -z "$DRY_RUN" ]; then
            log_error "NEURODAMUS_PYTHON var is not set. Unknown location of init.py"
            return 1
        fi
        INIT_ARGS=("-mpi" "-python" "$NEURODAMUS_PYTHON/init.py" "--configFile=$configfile" "--enable-shm=${SHM_ENABLED:-OFF}" --verbose "$@")
    else
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

    _test_results $output_root
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
    set -$(tr -d is <<< $_setbk)
elif [ $BASH_TRACE = yes ]; then
    set -x
fi
