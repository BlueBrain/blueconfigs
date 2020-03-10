#!/bin/bash

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
    sed -n "/^$section /,/}/p" "$blueconf" | grep "$1 "
}


#
# Comment / uncomment / change a Blueconfig line.

blue_comment() {
    local line="$1"
    local blueconf="${2:-BlueConfig}"
    local section="$3"
    if [ $section ]; then
        sed -i "/^$section /,/}/s#$line #\#$line #" "$blueconf"
    else
        sed -i "s#^$line #\#$line #" "$blueconf"
    fi
}

blue_uncomment() {
    local line="$1"
    local blueconf="${2:-BlueConfig}"
    local section="$3"
    if [ $section ]; then
        sed -i "/^$section /,/}/s#\#$line #$line #" "$blueconf"
    else
        sed -i "s#^\#$line #$line #" "$blueconf"
    fi
}

#
# Changes the first occurence of some entry in
blue_change() {
    local entry="$1"
    local newval="$2"
    local blueconf="${3:-BlueConfig}"
    local section="${4:-Run}"
    sed -i "/^$section /,/}/s#$entry .*#$entry $newval#" "$blueconf"
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
        sed -i "/^$section /,/}/s#}#    $entry $newval\n}#" "$blueconf"
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
