import libsonata
import sys

report1 = str(sys.argv[1])
report2  = str(sys.argv[2])

elements  = libsonata.ElementReportReader(report1)
elements2 = libsonata.ElementReportReader(report2)

# open population
population_elements = elements['All']
population_elements2 = elements2['All']

data_frame = elements['All'].get()
data_frame2 = elements2['All'].get()

if data_frame.data == data_frame2.data:
    exit(0)

exit(-1)
