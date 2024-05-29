import json
import sys

def update_longrun(json_file, outputdir, target):
    with open(json_file, 'r') as f:
        config = json.load(f)

    config["target_simulator"] = "CORENEURON"
    config["output"]["output_dir"] = outputdir
    config["node_set"] = target
    config["run"]["tstop"] = 500

    # No need for very dense reports
    for name, report in config.get("reports", {}).items():
        report["dt"] = 5

    with open(json_file, 'w') as f:
        json.dump(config, f, indent=2)

def update_simconf(json_file, section, key, value):
    with open(json_file, 'r') as f:
        data = json.load(f)

    # Parse the value if it's a JSON string
    try:
        value = json.loads(value)
    except json.JSONDecodeError:
        pass

    data[section][key] = value

    with open(json_file, 'w') as f:
        json.dump(data, f, indent=2)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: update_simconf.py <action> <json_file> [additional arguments]")
        sys.exit(1)

    action = sys.argv[1]
    json_file = sys.argv[2]

    if action == "update_longrun":
        if len(sys.argv) != 5:
            print("Usage: update_simconf.py update_longrun <json_file> <outputdir> <target>")
            sys.exit(1)
        outputdir = sys.argv[3]
        target = sys.argv[4]
        update_longrun(json_file, outputdir, target)
    elif action == "update_simconf":
        if len(sys.argv) != 6:
            print("Usage: update_simconf.py update_simconf <json_file> <section> <key> <value>")
            sys.exit(1)
        section = sys.argv[3]
        key = sys.argv[4]
        value = sys.argv[5]
        update_simconf(json_file, section, key, value)
    else:
        print("Unknown action")
        sys.exit(1)
