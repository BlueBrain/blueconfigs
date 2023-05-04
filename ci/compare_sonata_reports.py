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

    # At the moment then report1 is the reference, so b is the new
    # value, not the reference.
    # absolute(a - b) <= (atol + rtol * absolute(b))
    close_kwargs = {
        "rtol": 1e-16,
        "atol": 1e-16,
    }
    if numpy.allclose(df.values, df2.values, **close_kwargs):
        # Check all populations
        continue
    else:
        for node_id in node_ids:
            df_values = df[node_id].values
            df2_values = df2[node_id].values
            row_names = df[node_id].index
            if not numpy.allclose(df_values, df2_values, **close_kwargs):
                print(
                    ">>>> Different values for node id "
                    + str(node_id)
                    + " in population "
                    + pop_name
                    + ":"
                )
                # Loop through timesteps
                for i, timestep in enumerate(df_values):
                    if not numpy.allclose(timestep, df2_values[i], **close_kwargs):
                        # Loop through element ids
                        for j, element_value in enumerate(timestep):
                            ref_val, new_val = element_value, df2_values[i][j]
                            if not numpy.allclose(ref_val, new_val, **close_kwargs):
                                abs_diff = abs(ref_val - new_val)
                                rel_diff = 0.0
                                if abs(new_val) > 0:
                                    rel_diff = abs_diff / abs(new_val)
                                print(
                                    "[{:g}(ms)] ref {:.16f} vs output {:.16f} for element_id index {:d} (abs. diff {:.1e} rel. diff {:.1e})".format(
                                        row_names[i],
                                        ref_val,
                                        new_val,
                                        j,
                                        abs_diff,
                                        rel_diff,
                                    )
                                )
        # Exit with error on the first population that fails
        exit(-1)
    exit(0)
