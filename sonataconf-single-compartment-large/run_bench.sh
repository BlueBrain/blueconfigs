#!/usr/bin/env bash
#SBATCH --job-name=mmb-ndamus
#SBATCH --account=proj16
#SBATCH --partition=prod
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --exclusive
#SBATCH --mem=0
#SBATCH --constraint="cpu&clx"

# spack install -v neurodamus-neocortex@develop+coreneuron%intel ^py-neurodamus@develop%gcc ^coreneuron+caliper@develop%intel ^neuron@Develop%intel
module load unstable py-neurodamus/develop neurodamus-neocortex/develop

BASE_DIR=$(pwd)
MPI_RANKS=36
TSTOP=100
NCELLS=100000
CONNS_PER_CELL=3750
NSYN=$((${NCELLS}*${CONNS_PER_CELL}))
SIMULATOR="CORENEURON"

. setup_caliper.sh

output_suffix="${NCELLS}-${CONNS_PER_CELL}-${TSTOP}-${MPI_RANKS}"
echo "${output_suffix}"
output_log_name="output-neurodamus-${output_suffix}.log"
output_caliper_name="caliper-${output_suffix}.json"

srun -n $MPI_RANKS dplace special -mpi -python $NEURODAMUS_PYTHON/init.py --configFile=simulation_config.json --enable-shm --model-stats 2>&1 | tee ${output_log_name}

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

augment_caliper_json ${TSTOP} ${NCELLS} ${NSYN} ${model_size} ${emodel_size} ${synapse_size} ${SIMULATOR} ${MPI_RANKS} ${output_caliper_name}
