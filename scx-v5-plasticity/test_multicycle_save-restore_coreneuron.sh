#!/bin/bash
set -e
source ../toolbox.sh

blue_set Simulator CORENEURON $1
blue_comment "^Report" $1

export OMP_NUM_THREADS=1

source ./save-restore.sh $1 $2
