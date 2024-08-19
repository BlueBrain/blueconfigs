import neurodamus
import sys

CONFIG_FILE = "simulation_config.json"
if len(sys.argv) > 1:
    CONFIG_FILE = sys.argv[1]

nd = neurodamus.Neurodamus(
    CONFIG_FILE,
    keep_axon=True,
    auto_init=False,
    cleanup_atexit=False,
    logging_level=2,
)

print("Im done with modifications")
nd.init()

print("Will RUN Sim")
nd.run()
