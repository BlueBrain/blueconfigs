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

    export REFERENCE_REPORTS_VERSION="<latest_version_number>"

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

**25 May 2023**

* Updated reference spikes of long tests for `scx-v5-plasticity`, `quick-hip-multipopulation`, `mousify` and `thalamus`
* New reference spikes were generated with:
   - NEURON 9.0.a6 (commit=89f7dab)
   - CoreNEURON 9.0.a6 (commit=89f7dab)
   - py-neurodamus 2.15.0
   - Intel oneAPI Compiler 2022.2.1
   - libsonata-report 1.2

**24 May 2023**

* Updated reference reports of `scx-v5`, `scx-v6`, `scx-1k-v5`, `scx-2k-v6`, `scx-v5-gapjunctions`, `scx-v5-plasticity`, `sonataconf-quick-v5-plasticity`, `quick-v5-plasticity`, `quick-hip-delayconn`, `quick-hip-projSeed2`, `hip-v6` due to change from Intel Classic Compiler 2021.7.1 to Intel oneAPI LLVM based compier 2022.2.1.
* New reference reports were generated with:
   - NEURON 9.0.a6 (commit=89f7dab)
   - CoreNEURON 9.0.a6 (commit=89f7dab)
   - py-neurodamus 2.15.0
   - Intel oneAPI Compiler 2022.2.1
   - libsonata-report 1.2

**17 May 2023**

* [BBPBGLIB-1020] Updated SONATA reference reports of `quick-v5-gaps`, `quick-v5-multisplit`, `quick-v6`, `scx-1k-v5-newparams`, `thalamus`, `sonataconf-quick-scx-multi-circuit`, `sonataconf-quick-thalamus`, `scx-v5-bonus-minis`, `scx-v5-gapjunctions` and `mousify` to make sure that they are within tolerance with the generated reports after a change in the ProbAMPANMDA_EMS.mod common mod file
* New reference reports were generated with:
   - NEURON 9.0.a6 (commit=89f7dab)
   - CoreNEURON 9.0.a6 (commit=89f7dab)
   - py-neurodamus 2.15.0
   - Intel Classic Compiler 2021.7.0
   - libsonata-report 1.2

**4 May 2023**

* Updated SONATA reference reports of `quick-hip-delayconn`, `quick-v5-plasticity`, `sonataconf-quick-v5-plasticity`, `hip-v6`, `scx-v5-plasticity` and `scx-v5-gapjunctions` to make sure that they are within tolerance with the generated reports after failing for the past months to have an acceptable comparison tolerance that had as a result the files to be out of tolerance with the latest changes in the compiler version and compilation flags
* New reference reports were generated with:
   - NEURON 9.0.a2 (commit=89f7dab)
   - CoreNEURON 9.0.a2 (commit=89f7dab)
   - py-neurodamus 2.13.2
   - Intel Classic Compiler 2021.7.0
   - libsonata-report 1.2


Reference file updates
======================

In case we have to update multiple reference files there is an automatic way to do it.
In the above script to run the tests locally we can add the following before sourcing `.tests_setup.sh`:

.. code-block:: bash

    export ENABLE_REFERENCE_UPDATES="ON"

Then for every failure in the comparisons with the reference files the new generated files will be placed in the corresponding place.

For the spike reference files this means that there are going to be new `out.sorted` spike files generated that will replace the current ones in the repo. To update them we need to commit the changes and create an MR.

.. warning::

   !!!BE CAREFULL!!!

   For the report reference files the generated reports are going to be copied to the directory where the current reference reports lie. This is normally in `proj12` directory and GPFS and needs EXTREME CAREFULNESS when happening because this might interfere with all the CIs. The new reference reports will be copied to a file named that encodes whether `coreneuron` was enabled, the compiler name, the compiler version and the build type. In case a file exists with the same name THIS FILE WILL BE OVERWRITTEN!

   !!!BE CAREFULL!!!

After doing these changes the changes in the reference files need to be commited in the local git repo of `/gpfs/bbp.cscs.ch/project/proj12/jenkins` and documented in this README.
