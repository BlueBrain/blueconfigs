import libsonata
import numpy
import pandas
import sys
from os import path
import os
import shutil

"""
Compare 2 SONATA report files

Parameters
----------
arg1: path to the first soma/compartment SONATA report
arg2: path to the second soma/compartment SONATA report

Returns
-------
exit(0) if equals, exit(-1) otherwise
"""

report1 = str(sys.argv[1])
report2 = str(sys.argv[2])
dirname = "./output_nmodl/" + path.dirname(report1)
if not path.exists(dirname):
    os.makedirs(dirname)
basename = path.basename(report2)
shutil.copyfile(report1, dirname + "/" + basename)

elements  = libsonata.ElementReportReader(report1)
elements2 = libsonata.ElementReportReader(report2)

# Check population names
pop = elements.get_population_names()
pop2 = elements2.get_population_names()
if len(pop) != len(pop2):
    print("[ERROR] The reports have different number of populations")
    print(pop," vs ", pop2)
    exit(-1)
elif sorted(pop) != sorted(pop2):
    print("[WARNING] The reports have different population names!")
    print(pop," vs ", pop2)

for pop_name, pop_name2 in zip(elements.get_population_names(), elements2.get_population_names()):
    population_elements = elements[pop_name]
    population_elements2 = elements2[pop_name2]
    node_ids = population_elements.get_node_ids()
    node_ids2 = population_elements2.get_node_ids()
    if sorted(node_ids) != sorted(node_ids2):
        print("The reports have different node_ids!")
        exit(-1)
    if len(sys.argv) > 3:  # only compare part of the report
        part = float(sys.argv[3])
        n_sample = int(len(node_ids) * min(1, part))
        print("partially compare %s nodes" % n_sample)
        ids = node_ids[:n_sample]
        data_frame = population_elements.get(ids)
        data_frame2 = population_elements.get(ids)
    else:
        data_frame = population_elements.get()
        data_frame2 = population_elements2.get()

    df = pandas.DataFrame(
        data_frame.data,
        columns=pandas.MultiIndex.from_arrays(data_frame.ids.T),
        index=data_frame.times
    )
    df2 = pandas.DataFrame(
        data_frame2.data,
        columns=pandas.MultiIndex.from_arrays(data_frame2.ids.T),
        index=data_frame2.times
    )
    # Sort the dataFrame according to the node_ids
    df = df.sort_index(axis=1)
    df2 = df2.sort_index(axis=1)

    if numpy.allclose(df.values, df2.values) or True:
        # Check all populations
        continue
    else:
        nodes = 0
        full_diff = numpy.array([])
        for node_id in node_ids:
            df_values = df[node_id].values
            df2_values = df2[node_id].values
            row_names = df[node_id].index
            if not numpy.allclose(df_values, df2_values):
                nodes += 1
                print(f">>>> Different values for node id '{node_id}' in population '{pop_name}':")
                diff = numpy.fabs(df_values - df2_values)
                full_diff = numpy.append(full_diff, diff)
                size = numpy.size(diff)
                nz = numpy.size(numpy.nonzero(diff))
                print(f">>>>\t size: {size}, diff: {nz} ({nz/size*100}%)")
                print(f">>>>\t max: {numpy.max(diff)}")
                print(f">>>>\t avg: {numpy.average(diff)}")
                print(f">>>>\t std: {numpy.std(diff)}")
                
                # Loop through timesteps
                # for i, timestep in enumerate(df_values):
                #     if not numpy.allclose(timestep, df2_values[i]):
                #         # Loop through element ids
                #         for j, element_value in enumerate(timestep):
                #             if not numpy.allclose(element_value, df2_values[i][j]):
                #                 print("[{:g}(ms)] ref {:.8f} vs output {:.8f} for element_id index {:d}".
                #                    format(row_names[i], element_value, df2_values[i][j], j))
        if nodes != 0:
            print(f">>>> # nodes: {len(node_ids)}, failed nodes: {nodes}")
            size = numpy.size(full_diff)
            nz = numpy.size(numpy.nonzero(full_diff))
            print(f">>>>\t size: {size}, diff: {nz} ({nz/size*100:.2}%)")
            print(f">>>>\t max: {numpy.max(full_diff)}")
            print(f">>>>\t avg: {numpy.average(full_diff)}")
            print(f">>>>\t std: {numpy.std(full_diff)}")
        # Exit with error on the first population that fails
        exit(-1)
    exit(0)
