Hey @andras.ecker and @joseph.tharayil! How are you guys doing? I hope that the Summer is treating you well!

I'm reaching you because there is a new version of py-neurodamus on BB5 that integrates a new feature that we have been working on for the past month or so, and that it might benefit you and other scientists. Let me explain.

As you probably know, every time that you run a simulation with NEURON + CoreNEURON, there is a handover of the model and other data from NEURON to CoreNEURON. The files for the handover are stored into a coreneuron_input folder on GPFS, and unless you truly want to keep the model to re-run the same simulation again, this folder gets deleted every time. Hence, it is a waste of resources that implies writing thousands and thousands of files into GPFS, and at the end also deleting those files. For instance, for a 400-node job with 16K processes, almost 50K files will be written at the same time on GPFS (i.e., quite heavy for a parallel file system).

To be honest, the current handover mechanism was designed a few years ago and it works very well for most of the relatively large simulations. But in some cases, this might not be the case when you use hundreds of nodes, specially if there are other users also running simulations. What is worse, you also indirectly affect other users trying to use the cluster, despite that you are not doing anything wrong or trying to affect anybody.

To prevent this issue and in those scenarions when you run a simulation once and forget about it, we have designed a mechanism to transfer the model and other data without relying on GPFS. This is not the same work that Jorge and others started to develop some months ago, but it is an intermediate solution that can benefit you already today by simply using a different py-neurodamus. At the end of the day, you will not notice anything in your results, except the fact that the time spent to store the coreneuron_input might be potentially reduced to seconds.

At this point you may be wondering, why are you writing us for? Well, because I need your help to test this feature in real-world simulations.
