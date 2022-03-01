import libsonata
import numpy
import pandas
import sys

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

elements  = libsonata.ElementReportReader(report1)
elements2 = libsonata.ElementReportReader(report2)

# open population
population_elements = elements[elements.get_population_names()[0]]
population_elements2 = elements2[elements2.get_population_names()[0]]

if len(sys.argv) > 3:  # only compare part of the report
    part = float(sys.argv[3])
    node_ids = population_elements.get_node_ids()
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

if numpy.allclose(df.values, df2.values):
    exit(0)
else:
    for column_name in df.columns.get_level_values(0):
        df_values = df[column_name].values.ravel()
        df2_values = df2[column_name].values.ravel()
        row_names = df[column_name].index
        if not numpy.allclose(df_values, df2_values):
            print("Different values of " + str(column_name) + ": ")
            for i, value in enumerate(df_values):
                if not numpy.allclose(value, df2_values[i]):
                    print("[{:g}(ms)] ref {:.8f} vs output {:.8f}".format(row_names[i], value, df2_values[i]))
    exit(-1)
