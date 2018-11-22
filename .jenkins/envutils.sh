#!/bin/bash
# NOTE: This file shall be sourced so that important variables are avail to other scripts
ENVUTILS_LOADED=1
unset $(set +x; env | awk -F= '/^(PMI|SLURM)_/ {print $1}' | xargs)
unalias grep || true

Red='\033[0;31m'
Blue='\033[0;34m'
Green='\033[0;32m'
ColorReset='\033[0m'


# On error abort with a meaningful msg
error() (
    set +x
    echo -e "[$Red FATAL $ColorReset] Command returned $1."
)

trap 'error ${?}' ERR

if [[ -z "$ADDITIONAL_ENV_VARS" && -n "$GERRIT_CHANGE_COMMIT_MESSAGE" ]]; then
    ADDITIONAL_ENV_VARS=$(set +x; echo "$GERRIT_CHANGE_COMMIT_MESSAGE" | sed -n "s/^ENV_VARS://p")
fi
# Handle generic env variables set
[ $ADDITIONAL_ENV_VARS ] && eval $ADDITIONAL_ENV_VARS


bb5_run() (
    set +x
    # default partition is interactive
    partition=${partition:-"interactive"}
    hour=`date +%H`
    # during night is production
    if [ "$hour" -ge "20" ] || [ "$hour" -lt "8" ]; then partition="prod"; fi

    N=${N:-1}
    if [ -n "$n" ]; then
        limit="-n$n"
    fi

    cmd_base="salloc -p$partition -N$N $limit --ntasks-per-node=36 -Aproj16 --hint=compute_bound -Ccpu|nvme --time 1:00:00 srun --pty"
    echo "$cmd_base $@"
    $cmd_base "$@"
)
