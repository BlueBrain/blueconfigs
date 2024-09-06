#!/bin/sh
source ../toolbox.sh
echo $1
sonata_configfile_bk $1


update_simconf $sonataconfig "beta_features" "gapjunction_target_population" "thalamus_neurons"
update_simconf $sonataconfig "beta_features" "determanisitc_stoch" "true"
update_simconf $sonataconfig "beta_features" "procedure_type": "validation_sim"
update_simconf $sonataconfig "beta_features" "gjc" 0.2
update_simconf $sonataconfig "beta_features" "load_g_pas_file" "/gpfs/bbp.cscs.ch/project/proj55/amsalem/gap_junctions/circ19_11_2019_gjs_19_20_20/rm_correction/Circ_mc2_Rt_Remove_ch_all_Det_stoch_True_Dis_holding_False_Correc_type_impedance_tool_Cm0p01_Num_iter_10/num_0/g_pas_passive.hdf5"
update_simconf $sonataconfig "beta_features" "manual_MEComboInfo_file": "/gpfs/bbp.cscs.ch/project/proj55/amsalem/gap_junctions/circ19_11_2019_gjs_19_20_20_new_holding/find_holding_current/vc_ampFile/Circ_mc2_Rt_Remove_ch_none_Det_stoch_True_Dis_holding_False_gjc0p2_Change_mecomb_False_manual_MEComboInfoFile_False_Load_g_pas_True_Correc_iter_loadlast/num_0/holding_per_gid.hdf5"

echo "Run thalamus simulation with gap junction user corrections"
run_simulation $sonataconfig