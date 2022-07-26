#!/bin/bash
# NOTE: This file shall be sourced so that important variables are avail to other scripts
[ -n "$ENVUTILS_LOADED" ] && return || readonly ENVUTILS_LOADED=1
_setbk=$-

if [ -z "$TESTS_REUSE_ALLOCATION" ]; then
    unset $(env|awk -F= '/^(PMI|SLURM)_/ {if (match($1, "_(ACCOUNT|PARTITION)$")==0) print $1}')
fi

set +x
Red='\033[31m'
Green='\033[32m'
Yellow='\033[33m'
Blue='\033[34m'
ColorReset='\033[0m'

log() (
    set +x
    log_type=${2:-INFO}
    echo -e "[${3:-$Blue} $log_type $ColorReset] $1"
)

log_ok() { log "$1" ${2:-OK} $Green; }

log_warn() { log "$1" ${2:-WARNING} $Yellow; }

log_error() { log "$1" ${2:-ERROR} $Red; }

_contains () {  # Check if space-separated list $1 contains line $2
    [[ $1 =~ (^|[[:space:]])$2($|[[:space:]]) ]]
}


# On error abort with a meaningful msg
trap 'log_error "retcode ${?} at $BASH_SOURCE:$LINENO (cmd: ${BASH_COMMAND})"' ERR


if [[ -z "$ADDITIONAL_ENV_VARS" && -n "$GERRIT_CHANGE_COMMIT_MESSAGE" ]]; then
    ADDITIONAL_ENV_VARS=$(set +x; echo "$GERRIT_CHANGE_COMMIT_MESSAGE" | sed -n "s/^ENV_VARS://p")
fi
log "Checking for override hooks (ADDITIONAL_ENV_VARS or gerrit 'ENV_VARS:')..."
[ "$ADDITIONAL_ENV_VARS" ] && eval $ADDITIONAL_ENV_VARS


bb5_run() (
    set -e
    # default partition is interactive. during night use production
    hour=`date +%H`
    weekday=`date +%u`
    if [ -z "$SALLOC_PARTITION" ] && ([ "$hour" -ge "19" ] || [ "$hour" -lt "8" ] || [ $weekday -gt 5 ]); then
        export SALLOC_PARTITION="prod"
    fi

    export SALLOC_PARTITION="prod"

    N=${N:-1}
    if [ -n "$n" ]; then
        SALLOC_OPTS="$SALLOC_OPTS -n$n --reservation=shm_hpc"
    else
        SALLOC_OPTS="$SALLOC_OPTS --ntasks-per-node=36 --exclusive --mem=0 --reservation=shm_hpc"
    fi
    if [ -z "$SALLOC_ACCOUNT" ]; then
        if [ -n "$SLURM_JOB_ACCOUNT" ]; then
            SALLOC_OPTS="$SALLOC_OPTS -A$SLURM_JOB_ACCOUNT"
        else
            echo "Warning: No SALLOC_ACCOUNT or SLURM_JOB_ACCOUNT vars defined"
        fi
    fi
    if [ -z "$TESTS_REUSE_ALLOCATION" ]; then
        cmd_base="time salloc -N$N $SALLOC_OPTS --hint=compute_bound -Ccpu --time 1:00:00 srun dplace "
    else
        cmd_base="time srun dplace"
    fi

    echo "$cmd_base $@"
    if [ ! "$DRY_RUN"  ]; then
        $cmd_base "$@"
    fi
)
