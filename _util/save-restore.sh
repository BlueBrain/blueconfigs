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

seed1=${3:-0}
seed2=${4:-0}
seed3=${5:-0}

blue_set Duration $t_end1 "$config1"
blue_set SpikeFile input.dat "$config1"
blue_set Save "$output1/checkpoint" "$config1"

blue_set Duration $t_end2 "$config2"
blue_set OutputRoot "$output2" "$config2"
blue_set Restore "$output1/checkpoint" "$config2"
blue_set Save "$output2/checkpoint" "$config2"

blue_set OutputRoot "$output3" "$config3"
blue_set Restore "$output2/checkpoint" "$config3"

if [ $seed1 -gt 0 ]; then
    blue_set BaseSeed $seed1 "$config1"
fi
if [ $seed2 -gt 0 ]; then
    blue_set BaseSeed $seed2 "$config2"
fi
if [ $seed3 -gt 0 ]; then
    blue_set BaseSeed $seed3 "$config3"
fi

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
    [[ -f $rep && $rep != $output/out.h5 ]] || continue
    echo " >> >> >> Checking SONATA Report: $rep (len=$length)"
    actual_len=$(set +x; h5ls -r $rep | grep data | awk '{ print $3 }' | tr --delete {,)
    if [ $actual_len -ne $length ]; then
      echo "  ERROR: simulation length: $length != report length: $actual_len"
      return 1
    fi
  done  

)

echo " >> Running FIRST PART"
run_simulation "$config1"
echo " >> >> Checking report length of FIRST PART"
check_report_length "$output1" $t_end1

echo " >> Running SECOND PART"
run_simulation "$config2"
echo " >> >> Checking report length of SECOND PART"
check_report_length "$output2" $((t_end2 - t_end1))

echo " >> Running THIRD PART"
run_simulation "$config3"
echo " >> >> Checking report length of THIRD PART"
check_report_length "$output3" $((t_end3 - t_end2))

# Generate ascii format for the spikes in h5 for all directories
for directory in "$output1" "$output2" "$output3"; do
  if [ -f "$directory/out.h5" ]; then
    (set -x; python "$_THISDIR/../ci/generate_sonata_out.py" \
                    "$directory/out.h5" \
                    "$directory/out_SONATA.dat")
  fi
done

# delete bbp files otherwise the framework will try to compare them
rm -f $output1/*.bbp $output2/*.bbp $output3/*.bbp
rm -f $output1/*.h5 $output2/*.h5 $output3/*.h5

# Combine results to be tested against reference results
cat "$output2/out.dat" | grep -v scatter >> "$output1/out.dat"
cat "$output3/out.dat" | grep -v scatter >> "$output1/out.dat"

if [ -f "$output2/out_SONATA.dat" ]; then
  cat $output2/out_SONATA.dat >> $output1/out_SONATA.dat; fi
if [ -f "$output3/out_SONATA.dat" ]; then
  cat $output3/out_SONATA.dat >> $output1/out_SONATA.dat; fi

