import json
import sys


configfile = str(sys.argv[1])
outputdir = str(sys.argv[2])
target = str(sys.argv[3])

with open(configfile, "r") as f:
    config = json.load(f)

config["target_simulator"]="CORENEURON"
config["output"]["output_dir"]=outputdir
config["node_set"]=target
config["run"]["tstop"]=500

 # No need for very dense reports
for name, report in config.get("reports").items():
    report["dt"]=5

#overwrite configfile
with open(configfile, "w") as f:
    json.dump(config, f, indent=2)
