#!/usr/bin/env bash
#SBATCH --job-name=mmb-ndamus
#SBATCH --account=proj16
#SBATCH --partition=prod
#SBATCH --time=8:00:00
#SBATCH --nodes=2
#SBATCH --cpus-per-task=2
#SBATCH --exclusive
#SBATCH --mem=0
#SBATCH --constraint="cpu&clx"

module load unstable

# spack install -v --keep-stage neurodamus-neocortex@develop+coreneuron%intel ^py-neurodamus@develop%gcc ^coreneuron~caliper@develop%intel ^neuron@develop%intel
# spack load neurodamus-neocortex/kizmwf

module load py-neurodamus/develop neurodamus-neocortex/develop

BASE_DIR=$(pwd)
MPI_RANKS=$SLURM_NTASKS
TSTOP=100
NCELLS=70000000
CONNS_PER_CELL=1
NSYN=$((${NCELLS}*${CONNS_PER_CELL}))
SIMULATOR="CORENEURON"

# . setup_caliper.sh

output_suffix="${NCELLS}-${CONNS_PER_CELL}-${TSTOP}-${MPI_RANKS}-mmb-$(date +"%Y-%m-%d-%T")"
echo "${output_suffix}"
output_log_name="output-neurodamus-${output_suffix}.log"
output_caliper_name="caliper-${output_suffix}.json"

srun -n $MPI_RANKS dplace special -mpi -python $NEURODAMUS_PYTHON/init.py --configFile=simulation_config_70m_70m.json 2>&1 | tee ${output_log_name}

model_size=$(grep ${output_log_name} -e "Model size" | awk '{print $(NF - 1)}')
echo "Model size: ${model_size}"
NaTg_size=$(grep ${output_log_name} -e "NaTg" | tail -n 1 | awk '{print $NF}')
echo "NaTg size: ${NaTg_size}"
SKv3_size=$(grep ${output_log_name} -e "SKv3_1" | tail -n 1 | awk '{print $NF}')
echo "SKv3_1 size: ${SKv3_size}"
emodel_size=$(bc -l <<<"${NaTg_size}+${SKv3_size}")
ProbAMPANMDA_size=$(grep ${output_log_name} -e "ProbAMPANMDA" | tail -n 1 | awk '{print $NF}')
echo "ProbAMPANMDA size: ${ProbAMPANMDA_size}"
ProbGABAAB_size=$(grep ${output_log_name} -e "ProbGABAAB" | tail -n 1 | awk '{print $NF}')
echo "ProbGABAAB size: ${ProbGABAAB_size}"
synapse_size=$(bc -l <<<"${ProbAMPANMDA_size}+${ProbGABAAB_size}")

#augment_caliper_json ${TSTOP} ${NCELLS} ${NSYN} ${model_size} ${emodel_size} ${synapse_size} ${SIMULATOR} ${MPI_RANKS} ${output_caliper_name}
