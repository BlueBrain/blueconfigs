#!/bin/bash
source ../toolbox.sh

# If empty blue_* routines assume BlueConfig
configfile=$1

blue_set ProspectiveHosts $(( 2 * 2 * 36 )) $configfile # $ 2 loops with 2 nodes

