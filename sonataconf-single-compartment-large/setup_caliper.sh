export CALI_MPIREPORT_FILENAME=caliper.json
export CALI_MPIREPORT_LOCAL_CONFIG="SELECT sum(sum#time.duration),
                                           inclusive_sum(sum#time.duration)
                                    GROUP BY prop:nested"
export CALI_MPIREPORT_CONFIG='SELECT annotation,
                                     mpi.function,
                                     min(sum#sum#time.duration) as "exclusive_time_rank_min",
                                     max(sum#sum#time.duration) as "exclusive_time_rank_max",
                                     avg(sum#sum#time.duration) as "exclusive_time_rank_avg",
                                     min(inclusive#sum#time.duration) AS "inclusive_time_rank_min",
                                     max(inclusive#sum#time.duration) AS "inclusive_time_rank_max",
                                     avg(inclusive#sum#time.duration) AS "inclusive_time_rank_avg",
                                     percent_total(sum#sum#time.duration) AS "Exclusive time %",
                                     inclusive_percent_total(sum#sum#time.duration) AS "Inclusive time %"
                                     GROUP BY prop:nested FORMAT json'
export CALI_SERVICES_ENABLE=aggregate,event,mpi,mpireport,timestamp
# Everything not blacklisted is profiled. This list was stolen from Caliper...
export CALI_MPI_BLACKLIST="MPI_Comm_rank,MPI_Comm_size,MPI_Wtick,MPI_Wtime"
# Called after CoreNEURON has exited but in the context of the sbatch script
function augment_caliper_json {
  tstop="$1"
  ncells="$2"
  nsyn="$3"
  model_size="$4"
  emodel_size="$5"
  synapse_size="$6"
  backend="$7"
  mpi_ranks="$8"
  output_file="$9"
  module load jq
  jq_template="{\"data\": ."
  jq_template+=",\"tstop\": \"${tstop}\""
  jq_template+=",\"ncells\": \"${ncells}\""
  jq_template+=",\"nsyn\": \"${nsyn}\""
  jq_template+=",\"model_size\": \"${model_size}\""
  jq_template+=",\"emodel_size\": \"${emodel_size}\""
  jq_template+=",\"synapse_size\": \"${synapse_size}\""
  jq_template+=",\"backend\": \"${backend}\""
  jq_template+=",\"mpi_ranks\": \"${mpi_ranks}\""
  jq_template+=",\"env\": {"
  first=1
  for slurm_var in "${!SLURM_@}" "${!NVCOMPILER_@}" "${!CALI_@}"
  do
    if [[ ${first} == 1 ]];
    then
      first=0
    else
      jq_template+=","
    fi
    jq_template+="\"${slurm_var}\": \"$(echo ${!slurm_var} | sed -e 's/\"/\\\"/g')\""
  done
  jq_template+="}}"
  mv caliper.json caliper-${ncells}-${nsyn}-${backend}-${mpi_ranks}.json.orig
  jq "${jq_template}" < caliper-${ncells}-${nsyn}-${backend}-${mpi_ranks}.json.orig > ${output_file}
}
