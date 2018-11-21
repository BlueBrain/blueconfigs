#!/bin/bash

# Creates a sed expression to comment/uncomment several lines
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


# Comment / uncomment / change a Blueconfig line.
blue_comment() (
    line=$1
    blueconf=${2:-BlueConfig}
    sed -i "s#$line#\#$line#" $blueconf
)

blue_uncomment() (
    line=$1
    blueconf=${2:-BlueConfig}
    sed -i "s#\#$line#$line#" $blueconf
)

blue_change() (
    entry=$1
    newval=$2
    blueconf=${3:-BlueConfig}
    sed -i "s#$entry.*#$entry $newval#" $blueconf
)

# Uncomments or adds if non-existing then set value
blue_set() (
    entry=$1
    newval=$2
    blueconf=${3:-BlueConfig}
    grep $entry $blueconf > /dev/null
    if [ $? -ne 0 ]; then
        # add before first closing tag
        sed -i "0,/}/s//    $entry $newval\n}/" $blueconf
    else
        blue_uncomment $entry $blueconf
        blue_change $entry $newval $blueconf
    fi
)
