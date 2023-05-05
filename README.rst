============
blueconfigs
============

Set of Neurodamus test simulations that run in the CI.


Run locally
============

.. code-block:: bash

    git clone git@bbpgitlab.epfl.ch:hpc/sim/blueconfigs.git
    cd blueconfigs

    export HOME=`pwd`
    export SALLOC_ACCOUNT=proj16
    export TEST_VERSIONS="ncx_plasticity"

    export SPACK_BRANCH=my_spack_branch
    export <SPACK_PACKAGE_NAME>_BRANCH=my_package_branch
    export <SPACK_PACKAGE_NAME>_TAG=my_package_tag
    export <SPACK_PACKAGE_NAME>_COMMIT=my_package_commit

    export RUN_PY_TESTS='yes'
    export RUN_HOC_TESTS='no'

    source .tests_setup.sh
    install_neurodamus
    # Run all the "ncx_plasticity" tests
    run_all_tests
    # Run only one specific test with the proper spec
    run_test sonataconf-quick-v5-plasticity "${VERSIONS[ncx_plasticity]}"


Reference files
===============

This repository compares every output of the included simulations (reports and spikes) with reference files.

The goal of those integration tests are to test the whole neurodamus workflow and make sure that the final spikes are exactly the same and the reports are within tight tolerances (atol: 1e-16, rtol: 1e-16).
The tolerances are set tight enough so that we can identify any changes in our software or compilers and make sure we understand the changes and if needed update the reference files.

The paths to the reference files can be found in `ci/testutils.sh` where we set an environmental variable `REF_RESULTS`. Also note that there is a local git repository set up in `/gpfs/bbp.cscs.ch/project/proj12/jenkins` that should be used to document the exact changes in the reference files.

To make sure we understand all the changes to the reference files we should document any changes to them with timestamp and the related software stack (NEURON version, py-neurodamus version, Compiler version and build type/compilation flags, libsonata-report version, or any other software package that might influence the results of the simulation).

Currently, the reports are all in SONATA form and their naming convention is `<report_name><_coreneuron>_<compiler_name>_<compiler_version>_<build_type>.h5`. `_coreneuron` is only added if the reports are intended to be compared only with the CoreNEURON enabled report. In case a file with this naming convention doesn't exist then we fall back in looking for a file with a name `<report_name>.h5` which normally is the default generated report by a NEURON simulation.

Note: There are cases where for some reason CoreNEURON reports have slightly different results compared to NEURON due to the compilation flags being used and the additional code optimizations.

Below are the timestamps of the updates to the reference files:

**4 May 2023**

* Updated SONATA reference reports of `quick-hip-delayconn`, `quick-v5-plasticity`, `sonataconf-quick-v5-plasticity`, `hip-v6`, `scx-v5-plasticity` and `scx-v5-gapjunctions` to make sure that they are within tolerance with the generated reports after failing for the past months to have an acceptable comparison tolerance that had as a result the files to be out of tolerance with the latest changes in the compiler version and compilation flags
* New reference reports were generated with:
   - NEURON 9.0.a2 (commit=89f7dab)
   - CoreNEURON 9.0.a2 (commit=89f7dab)
   - py-neurodamus 2.13.2
   - Intel Classic Compiler 2021.7.0
   - libsonata-report 1.2
