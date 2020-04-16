#!/bin/bash
set -e
_bc="${1:-BlueConfig}"
config1="${_bc}.first"
config2="${_bc}.second"
config3="${_bc}.third"

output1="${2:-output}"
output2="${output1}.second"
output3="${output1}.third"

blue_set Dt "1.0" "$_bc" "Report"
cp "$_bc" "$config1"
cp "$_bc" "$config2"
cp "$_bc" "$config3"

t_end1=40
t_end2=70
t_end3=100

blue_set Duration $t_end1 "$config1"
blue_set SpikeFile input.dat "$config1"
blue_set Save "$output1/checkpoint" "$config1"

blue_set Duration $t_end2 "$config2"
blue_set OutputRoot "$output2" "$config2"
blue_set Restore "$output1/checkpoint" "$config2"
blue_set Save "$output2/checkpoint" "$config2"

blue_set OutputRoot "$output3" "$config3"
blue_set Restore "$output2/checkpoint" "$config3"


check_report_length() (
  output="$1"
  length="$2"
  set -e

  for rep in "$output"/*.bbp; do
    [[ -f $rep && $rep != $output/checkpoint.bbp ]] || continue
    actual_len=$(somaDump "$rep" $(listgid "$rep" | head -n1) | wc -l)
    echo " > Checking report length: $rep (len=$length)"
    if [ $actual_len -ne $length ]; then
      echo "  ERROR: $length != $actual_len"
      return 1
    fi
  done

  for rep in $output/*.h5; do
     [[ -f "$rep" && "$rep" != $output/out.h5 ]] || continue
     [ $(set +x; h5ls -r $rep | grep data | awk '{ print $3 }' | tr --delete {,) -eq $length ]
  done

  for rep in $output/*.h5; do
     [[ -f "$rep" && "$rep" != $output/out.h5 ]] || continue
     [ $(set +x; h5ls -r $rep | grep data | awk '{ print $3 }' | tr --delete {,) -eq $length ]
  done

)

echo " >> Running FIRST PART"
run_blueconfig "$config1"
check_report_length "$output1" $t_end1

echo " >> Running SECOND PART"
run_blueconfig "$config2"
check_report_length "$output2" $((t_end2 - t_end1))

echo " >> Running THIRD PART"
run_blueconfig "$config3"
check_report_length "$output3" $((t_end3 - t_end2))

# Generate ascii format for the spikes in h5 for all directories
output_directories=( "$output1" "$output2" "$output3" )
for directory in "${output_directories[@]}"
do
    if [ -f $directory/out.h5 ]; then
        data=$(h5dump -d /spikes/All/timestamps -m %.3f -d /spikes/All/node_ids -y -O $directory/out.h5 | tr "," "\n")
        :>$directory/out_SONATA.dat
        echo $data | awk '{n=NF/2; for (i=1;i<=n;i++) print $i "\t" $(n+i+1) }' >> $directory/out_SONATA.dat
    fi
done

# Generate ascii format for the spikes in h5 for all directories
output_directories=( "$output1" "$output2" "$output3" )
for directory in "${output_directories[@]}"
do
    if [ -f $directory/out.h5 ]; then
        data=$(h5dump -d /spikes/timestamps -m %.3f -d /spikes/node_ids -y -O $directory/out.h5 | tr "," "\n")
        :>$directory/out_SONATA.dat
        echo $data | awk '{n=NF/2; for (i=1;i<=n;i++) print $i "\t" $(n+i+1) }' >> $directory/out_SONATA.dat
    fi
done

# delete bbp files otherwise the framework will try to compare them
rm -f $output1/*.bbp $output2/*.bbp $output3/*.bbp
rm -f $output1/*.h5 $output2/*.h5 $output3/*.h5

# Combine results to be tested against reference results
cat "$output2/out.dat" | grep -v scatter >> "$output1/out.dat"
cat "$output3/out.dat" | grep -v scatter >> "$output1/out.dat"

cat $output2/out_SONATA.dat >> $output1/out_SONATA.dat
cat $output3/out_SONATA.dat >> $output1/out_SONATA.dat
