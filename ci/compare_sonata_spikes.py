import libsonata
import sys

ref = str(sys.argv[2])
result = str(sys.argv[1])

spikes_ref = libsonata.SpikeReader(ref)
spikes_result = libsonata.SpikeReader(result)
population_names = spikes_ref.get_population_names()
for name in population_names:
    data_ref = spikes_ref[name].get()
    data_result = spikes_result[name].get()
    # data : list of (gid, time), sort by time
    data_ref.sort(key=lambda tup: tup[1])
    data_result.sort(key=lambda tup: tup[1])
    if data_result == data_ref:
        exit(0)

    diff = [x for x in data_result if x not in data_ref]
    if diff:
        print("Spikes from result report not found in reference:")
        for x in diff:
            print("{:.8f} {:g}".format(x[1], x[0]))
    else:
        diff = [x for x in data_ref if x not in data_result]
        print("Spikes from reference report not found in reference:")
        for x in diff:
            print("{:.8f} {:g}".format(x[1], x[0]))
    exit(-1)
