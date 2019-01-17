#!/bin/bash
set -e
_bc=${1:-BlueConfig}
config1=${_bc}.first
config2=${_bc}.second
config3=${_bc}.third

output1=${2:-output}
output2=${output1}.second
output3=${output1}.third

blue_set Dt "2.0" $_bc '^Report'
cp $_bc $config1
cp $_bc $config2
cp $_bc $config3

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

# delete bbp files otherwise the framework will try to compare them
rm -f $output1/*.bbp $output2/*.bbp $output3/*.bbp

# Combine results to be tested against reference results
cat $output2/out.dat >> $output1/out.dat
cat $output3/out.dat >> $output1/out.dat

