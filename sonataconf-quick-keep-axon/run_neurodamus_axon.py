import neurodamus

nd = neurodamus.Neurodamus(
    "simulation_config.json",
    keep_axon=True,
    auto_init=False,
    cleanup_atexit=False,
    logging_level=2,
)

#import pdb; pdb.set_trace()

print("Im done with modifications")
nd.init()

print("Will RUN Sim")
nd.run()

