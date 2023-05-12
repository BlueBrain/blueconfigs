#!/usr/bin/env bash
#SBATCH --job-name=ndamus-container
#SBATCH --account=proj16
#SBATCH --partition=prod
#SBATCH --time=8:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --constraint="cpu&clx"
#SBATCH --exclusive
#SBATCH --mem=0

module purge
module load unstable
module load singularityce

rm -rf output mcomplex.dat sim_conf

srun dplace singularity run --env "LD_PRELOAD=$LD_PRELOAD" --no-eval -B /gpfs/bbp.cscs.ch/ /gpfs/bbp.cscs.ch/ssd/containers/hpc/spackah/neurodamus-neocortex_1.11-2.15.0-2.6.5.sif 'eval special -mpi -python $NEURODAMUS_PYTHON/init.py --configFile=$(realpath $(pwd))/BlueConfig --enable-shm=OFF'

