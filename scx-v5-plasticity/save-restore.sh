#!/bin/bash
configfile=$1
config1=${configfile}.first
config2=${configfile}.second
config3=${configfile}.third

output1=$2
output2=${output1}.second
output3=${output1}.third

blue_set Dt "2.0" $configfile '^Report'
cp $configfile $config1
cp $configfile $config2
cp $configfile $config3

blue_set Duration 40 $config1
blue_set SpikeFile input.dat $config1
blue_set Save "$output1/checkpoint" $config1

blue_set Duration 70 $config2
blue_set OutputRoot $output2 $config2
blue_set Restore "$output1/checkpoint" $config2
blue_set Save "$output2/checkpoint" $config2

blue_set OutputRoot $output3 $config3
blue_set Restore "$output2/checkpoint" $config3


check_report_length() (
  output=$1
  length=$2
  set -xe

  for rep in $output/*.bbp; do
     [[ -f "$rep" && "$rep" != $output/checkpoint.bbp ]] || continue
     [ $(set +x; somaDump $rep $(listgid $rep | head -n1) | wc -l) -eq $length ]
  done
  # We need to delete these reports, otherwise the framework wil compare them
  rm -f $output/*.bbp
)

echo "Running FIRST PART"
run_blueconfig $config1
check_report_length $output1 20

echo "Running SECOND PART"
run_blueconfig $config2
check_report_length $output2 15

echo "Running THIRD PART"
run_blueconfig $config3
check_report_length $output3 15

# Combine results to be tested against reference results
cat $output2/out.dat >> $output1/out.dat
cat $output3/out.dat >> $output1/out.dat

