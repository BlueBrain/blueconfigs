import libsonata
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
population_elements = elements[elements.get_populations_names()[0]]
population_elements2 = elements2[elements2.get_populations_names()[0]]

data_frame = population_elements.get()
data_frame2 = population_elements2.get()

if data_frame.data == data_frame2.data:
    exit(0)

exit(-1)
