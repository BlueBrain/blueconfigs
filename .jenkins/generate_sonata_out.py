import libsonata
import sys

"""
Generates SONATA spike file into the old format

Parameters
----------
arg1: path to the out.h5 file (spikes SONATA file)

Returns
-------
generates out_SONATA.dat spike file in old format
"""
report = str(sys.argv[1])

spikes = libsonata.SpikeReader(report)

# open population
population_spikes = spikes[spikes.get_population_names()[0]]
data = population_spikes.get()

# create out_SONATA file
with open('out_SONATA.dat', 'a') as f:
    for gid, time in data:
        f.write('%.3f\t%d\n' % (time, gid+1))
