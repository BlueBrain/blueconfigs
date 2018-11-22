#!/bin/bash
source ../toolbox.sh
configfile=$1

blue_set ProspectiveHosts $(( 2 * 2 * 36 )) $configfile # $ 2 loops with 2 nodes
blue_set Simulator CORENEURON $configfile
blue_comment Report $configfile

run_blueconfig $blueconfig
