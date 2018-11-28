#!/bin/bash
set -e
spack load reportinglib

source ../toolbox.sh

blue_set Simulator CORENEURON $1

export OMP_NUM_THREADS=1

SALLOC_OPTS='--exclusive --mem=0'
source ./save-restore.sh $1 $2
