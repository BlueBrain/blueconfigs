#!/bin/bash
[ $ENVUTILS_LOADED ] || source "${BASH_SOURCE%/*}/envutils.sh"
BLUECONFIG_DIR=`pwd`

# defaults
RUN_PY_TESTS="${RUN_PY_TESTS:-no}"
DATADIR="${DATADIR:-/gpfs/bbp.cscs.ch/project/proj12/jenkins}"

# list of simulation results
EXTENDED_RESULTS="$DATADIR/cellular"
declare -A REF_RESULTS
REF_RESULTS["scx-v5"]="$EXTENDED_RESULTS/circuit-scx-v5/simulation"
REF_RESULTS["scx-v6"]="$EXTENDED_RESULTS/circuit-scx-v6/simulation"
REF_RESULTS["scx-1k-v5"]="$EXTENDED_RESULTS/circuit-1k/simulation"
REF_RESULTS["scx-2k-v6"]="$EXTENDED_RESULTS/circuit-2k/simulation"
REF_RESULTS["scx-v5-gapjunctions"]="$EXTENDED_RESULTS/circuit-scx-v5-gapjunctions/simulation"
REF_RESULTS["scx-v5-bonus-minis"]="$EXTENDED_RESULTS/circuit-scx-v5-bonus-minis/simulation"
REF_RESULTS["scx-v5-plasticity"]="$EXTENDED_RESULTS/circuit-scx-v5-plasticity/simulation"
REF_RESULTS["hip-v6"]="$EXTENDED_RESULTS/circuit-hip-v6/simulation"
REF_RESULTS["quick-v5-gaps"]="$EXTENDED_RESULTS/circuit-scx-v5-gapjunctions/simulation_quick"
REF_RESULTS["quick-v6"]="$EXTENDED_RESULTS/circuit-2k/simulation_quick"


_prepare_test() {
    # If test not provided check if curdir has BlueConfig
    if [ -z "$testname" ]; then
        if [[ -f BlueConfig && -f out.sorted ]]; then
            testname="${PWD##*/}"
        else
            echo "Test name not provided and not found in cur dir"
            exit -1
        fi
    else
        cd $BLUECONFIG_DIR/$testname
    fi

    # If neurodamus spec not given, check cur loaded
    if [ -z "$spec" ]; then
        spec=default
        which special  # Ensure available
    fi

    # To run in parallel output and BlueConfig must be unique
    hash=$(echo $spec | md5sum | cut -c 1-8)
    cp BlueConfig "BlueConfig_$hash"

    blueconfigs=("BlueConfig_$hash")
    declare -gA outputs

    # Try find test_* scripts, which generate more BlueConfigs
    for bc_script in test_*.sh; do
        [ -f $bc_script ] || break  # bash will take it literally when does not exist
        bc_copy="BlueConfig_${bc_script:5:-3}_$hash"
        cp BlueConfig $bc_copy
        sh $bc_script $bc_copy
        blueconfigs+=( "$bc_copy" )
    done

    # Patch all Blueconfigs, clean exisiting res
    for bc in ${blueconfigs[@]}; do
        suffix=${bc:11}
        _output=output_$suffix
        sed -i "s#OutputRoot.*#OutputRoot $_output#" $bc
        outputs["$bc"]=$_output
        rm -rf $_output
    done

    # load env modules
    set +x
    echo -e "\n[$Blue INFO $ColorReset] Running test $testname ($spec) #$hash"
    echo -e "[$Blue INFO $ColorReset] ------------------"

    if [ $spec != "default" ]; then
        echo "COMMANDS: module purge; spack load $spec"
        module purge
        if [ $RUN_PY_TESTS = "yes" ]; then spack load python; fi
        spack load $spec
    fi
    module list
    module list -t 2>&1 | grep neurodamus | while read mod; do module show "$mod"; done
}


test_check_results() (
    set -ex
    output=$1
    ref_results=$2
    ref_spikes=${3:-out.sorted}
    # Print nice msg on error
    trap "(set +x; echo -e \"[$Red Error $ColorReset] Results DON'T Match\n\"; exit 1)" ERR

    [ -f $output/spikes.dat ] && mv $output/spikes.dat $output/out.dat
    # Core neuron doesnt have a /scatter (!?)
    grep '/scatter' $output/out.dat || sed -i '1s#^#/scatter\n#' $output/out.dat
    sort -n -k'1,1' -k2 < $output/out.dat | awk 'NR==1 { print; next } { printf "%.3f\t%d\n", $1, $2 }' > $output/out.sorted
    diff -wy --suppress-common-lines $ref_spikes $output/out.sorted

    # compare reports
    set +x
    for report in $(cd $output && ls *.bbp); do
        (set -x; cmp "$ref_results/$report" "$output/$report")
    done
    echo -e "[$Green OK $ColorReset] Results Match\n"
)


run_test() (
    set -e
    testname=$1
    spec=$2
    export OMP_NUM_THREADS=2

    # Will set $blueconfigs and an $output associate array
    _prepare_test

    if [ ${#blueconfigs[@]} -eq 1 ]; then
        run_blueconfig $blueconfigs
    	test_check_results "${outputs[$blueconfigs]}" "${REF_RESULTS[$testname]}"
    else
        # Otherwise we launch several processes to the background, store output and wait
        # Loop over $blueconfig tests
        declare -A pids
        for bc in ${blueconfigs[@]}; do
            echo -e "$Green => $ColorReset Starting simulation from $bc in parallel"
            run_blueconfig $bc &> _$bc.log &
            pids[$bc]=$!
        done

        sleep 10  # Some time to have salloc info
        for bc in ${blueconfigs[@]}; do
            echo -e "[$Blue Info $ColorReset] Simulation $bc status:"
            grep 'salloc:' _$bc.log | sed 's/^/    /'
        done

        # Run checks in fg
        ERR=
        echo
        for bc in ${blueconfigs[@]}; do
            echo -e "$Green => $ColorReset Waiting for simulation $bc results"
            wait ${pids[$bc]} || {
                echo -e "[$Red Error $ColorReset] Failed to run simulation. Log:"; cat _$bc.log; ERR=y
                continue
            }

            echo "Simulation log:"; cat _$bc.log

            # Inner -e is not respected if we have '||'. We need to check $?
            set +e
            test_check_results "${outputs[$bc]}" "${REF_RESULTS[$testname]}"
            [ $? -eq 0 ] || ERR=y
            set -e
        done

        if [ $ERR ]; then
            echo -e "[$Red FAIL $ColorReset] Tests $testname failed\n"
            return 1
        fi
    fi

    echo -e "[$Green PASS $ColorReset] Tests $testname successfull\n"
)


# Run neurodmus directly on a given blueconfig
run_blueconfig() (
    set -e
    configfile=$1

    if [[ $RUN_PY_TESTS == "yes" && $NEURODAMUS_PYTHON ]]; then
        INIT_ARGS=("-python" "$NEURODAMUS_PYTHON/init.py" "--configFile=$configfile")
    else
        INIT_ARGS=("-c" "{strdef configFile configFile=\"$configfile\"}" "$HOC_LIBRARY_PATH/init.hoc")
    fi

    N=$(set -x; [[ $testname =~ quick* ]] && echo 1 || echo 2) \
    bb5_run special "${INIT_ARGS[@]}" -mpi
)


run_debug() (
    testname=$1
    spec=$2
    _prepare_test

    bb5_run special $HOC_LIBRARY_PATH/_debug.hoc -mpi

    # compare nrndat
    for nrnfile in *.nrndat; do
        (set -x
         diff -wy --suppress-common-lines expected_nrndat/$nrnfile $nrnfile)
    done
)


# Prepare for immediate test run
if [ -z $SPACK_ROOT ]; then
    echo "Warning: no SPACK_ROOT. Please setup spack before launching tests. Consider sourcing '.tests_setup.sh' instead"
else
    _set=$-; set +x -e
    source $SPACK_ROOT/share/spack/setup-env.sh
    set +e -$_set
fi
