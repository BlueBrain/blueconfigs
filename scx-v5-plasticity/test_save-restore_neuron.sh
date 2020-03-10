#!/bin/bash
set -e
module load unstable reportinglib
module list

source ../toolbox.sh
configfile_bk $1
outputdir=$2

source ./save-restore.sh $blueconfig $outputdir
