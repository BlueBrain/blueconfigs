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


# Changes the first occurence of some entry in
blue_change() (
    entry=$1
    newval=$2
    blueconf=${3:-BlueConfig}
    section=${4:-'^Run'}
    sed -i "/${section}/,/}/s#$entry.*#$entry $newval#" $blueconf
)

# Uncomments or adds if non-existing then set value
blue_set() (
    entry=$1
    newval=$2
    blueconf=${3:-BlueConfig}
    section=${4:-'^Run'}
    if (grep $entry $blueconf > /dev/null); then
        blue_uncomment $entry $blueconf
        blue_change $entry $newval $blueconf $section
    else
        # add before first closing tag
        sed -i "/${section}/,/}/s#}#    $entry $newval\n}#" $blueconf
    fi
)

# Copies the configfile to avoid messing the original
# Sets new variable $configfile
configfile_bk() {
    f0=${1:-BlueConfig}
    blueconfig=${f0}.copy
    cp $f0 $blueconfig
}

