#!/bin/bash

# Get the directory of the current script
THISDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Creates a sed expression to comment/uncomment several lines
_sed_comment() {
    local _expr=""
    local line
    for line in "$@"; do
        _expr="$_expr; s/$line/#$line/"
    done
    echo $_expr
}

_sed_uncomment() {
    local _expr=""
    local line
    for line in "$@"; do
        _expr="$_expr; s/#$line/$line/"
    done
    echo $_expr
}

_get_line() {
    # find $1 in file $2 within section $3
    local blueconf="${2:-BlueConfig}"
    local section="${3:-Run}"
    sed -n "/^$section\b/,/}/p" "$blueconf" | grep "$1 "
}


#
# Comment / uncomment / change a Blueconfig line.

blue_comment() {
    local line="$1"
    local blueconf="${2:-BlueConfig}"
    local section="${3:-Run}"
    sed -i "/^$section\b/,/}/s#$line #\#$line #" "$blueconf"
}

blue_comment_section()  {
    local line="$1"
    local blueconf="${2:-BlueConfig}"
    sed -i "s#^$line\b#\#$line#" "$blueconf"

}

blue_uncomment() {
    local line="$1"
    local blueconf="${2:-BlueConfig}"
    local section="${3:-Run}"
    sed -i "/^$section\b/,/}/s#\#$line #$line #" "$blueconf"
}

blue_uncomment_section() {
    local line="$1"
    local blueconf="${2:-BlueConfig}"
    sed -i "s#^\#$line\b#$line#" "$blueconf"
}

#
# Changes the first occurence of some entry in
blue_change() {
    local entry="$1"
    local newval="$2"
    local blueconf="${3:-BlueConfig}"
    local section="${4:-Run}"
    sed -i "/^$section\b/,/}/s#$entry .*#$entry $newval#" "$blueconf"
}

#
# Uncomments or adds if non-existing then set value
blue_set() (
    set -e
    entry=$1
    newval=$2
    blueconf="${3:-BlueConfig}"
    section="${4:-Run}"
    if (_get_line $entry "$blueconf" "$section" > /dev/null); then
        blue_uncomment $entry "$blueconf" "$section"
        blue_change $entry $newval "$blueconf" "$section"
    else
        # add before first closing tag
        sed -i "/^$section\b/,/}/s#}#    $entry $newval\n}#" "$blueconf"
    fi
)

#
# Finds an entry and returns its value
blue_get() (
    set -e
    entry=$1
    line=$(_get_line $entry "$2" "$3")
    echo ${line/$entry/}
)


# Copies the configfile to avoid messing the original
# Sets new variable $configfile
configfile_bk() {
    local f0="${1:-BlueConfig}"
    blueconfig="${f0}.copy"
    cp "$f0" "$blueconfig"
}

# Copies the sonata configfile to avoid messing the original
# Sets new variable $configfile
sonata_configfile_bk() {
    local f0="${1:-simulation_config.json}"
    sonataconfig=${f0%".json"}".copy.json"
    cp "$f0" "$sonataconfig"
}

# Sets "entry" of SONATA file "sonataconf" to "newval".
sonataconf_set() (
    set -ex
    entry=$1
    newval=$2
    sonataconf="${3:-simulation_config.json}"
    sed -i "s#\"${entry}\": \".*\"#\"${entry}\": \"${newval}\"#g" "$sonataconf"
)

# Function to update a key-value pair in a specified section of simulation_config.json using Python
update_simconf() {
    local json_file="${1:-simulation_config.json}"
    local section="${2}"
    local key="${3}"
    local value="${4}"
    python $THISDIR/ci/update_simconf.py update_simconf "$json_file" "$section" "$key" "$value"
}
