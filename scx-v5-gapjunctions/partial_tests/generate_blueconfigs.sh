#!/bin/sh
_set=$-; set -e

PROJECTION_BLOCKS=("Projection gapjunction" "Projection Thalamocortical_input_VPM")
REPLAY_BLOCKS=("Stimulus spikeReplay" "StimulusInject spikeReplayIntoUniverse")
ALL_EXTRAS=( "${PROJECTION_BLOCKS[@]}" "${REPLAY_BLOCKS[@]}" )

_sed_comment() (
    _expr=""
    for line in "$@"; do
        _expr="$_expr; s/$line/#$line/"
    done
    echo $_expr
)

_sed_uncomment() (
    _expr=""
    for line in "$@"; do
        _expr="$_expr; s/#$line/$line/"
    done
    echo $_expr
)

create_bare_v5() (
    cp BlueConfig BlueConfig.bare
    sed -i "$(_sed_comment "${ALL_EXTRAS[@]}")" BlueConfig.bare
    # Fix delay, length, target, output
    sed -i "s#CircuitTarget Column1k#CircuitTarget miniColumn#;
            s#Duration 100#Duration 50#;
            s#Delay 50#Delay 10#;
            s#OutputRoot.*#OutputRoot output_bare#" BlueConfig.bare
)


# Create the new BlueConfigs
create_bare_v5

# Only projection
sed "$(_sed_uncomment "${PROJECTION_BLOCKS[@]}");
     s#OutputRoot.*#OutputRoot output_gaps#"  BlueConfig.bare > BlueConfig.gaps
# plus replay
sed "$(_sed_uncomment "${REPLAY_BLOCKS[@]}");
     s#OutputRoot.*#OutputRoot output_replay#" BlueConfig.gaps > BlueConfig.replay


# Helpers

_run_test() (
    set -e
    if [ -z $HOC_LIBRARY_PATH ]; then
        echo "Please load neurodamus"
        exit -1
    fi
    version=$1  # bare, gaps, replay
    refresults=$DATADIR/cellular/circuit-scx-v5-gapjunctions/simulation_partial
    set -x
    run_simulation BlueConfig.$version
    test_check_results output_$version $refresults/output_$version partial_tests/out_$version.sorted
)

run_partial_tests() (
    set -e
    _run_test bare
    _run_test gaps
    _run_test replay
)

set +e -$_set

