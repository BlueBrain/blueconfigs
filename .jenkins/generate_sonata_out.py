import libsonata
import sys

"""
Generates SONATA spike file into the old format

Parameters
----------
arg1: path to the out.h5 file (spikes SONATA file)

Returns
-------
generates SONATA output spike file in old format
"""
report = str(sys.argv[1])
output = str(sys.argv[2]) if len(sys.argv) == 3 else "out_SONATA.dat"

spikes = libsonata.SpikeReader(report)

# open population
population_spikes = spikes[spikes.get_population_names()[0]]
data = population_spikes.get()

# create SONATA output file
with open(output, 'w') as f:
    for gid, time in data:
        f.write('%.3f\t%d\n' % (time, gid+1))
