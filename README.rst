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
    # values can be neocortex, ncx_bare, ncx_plasticity, hippocampus, thalamus, mousify or ncx_ngv
    # if none is set it will run all tests
    export TEST_VERSIONS="ncx_plasticity"

    # The next steps are useful if you don't run when a spack is active
    export SPACK_BRANCH=my_spack_branch
    export <SPACK_PACKAGE_NAME>_BRANCH=my_package_branch
    export <SPACK_PACKAGE_NAME>_TAG=my_package_tag
    export <SPACK_PACKAGE_NAME>_COMMIT=my_package_commit

    export RUN_PY_TESTS='yes'
    export RUN_HOC_TESTS='no'

    export REFERENCE_REPORTS_VERSION="<latest_version_number>" # check .gitlab-ci.yaml default value

    source .tests_setup.sh
    install_neurodamus
    # Run all the "ncx_plasticity" tests
    run_all_tests
    # Run only one specific test with the proper spec
    run_test sonataconf-quick-v5-plasticity "${VERSIONS[ncx_plasticity]}"


Gitlab CI
=========

The default run on Merge Request is a dry run.
Launch by hand to have a full run.
You can set: `SPACK_BRANCH` and `NEURON_BRANCH` to tweak the build.


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

**26 Jan 2024**

* Updated reference report for `sonataconf-quick-v5-plasticity` CoreNEURON simulation
* New reference file have `v6` in its name
* Was done due to updates in NEURON related to summation reports in cell targets and SONATA simulations: https://github.com/neuronsimulator/nrn/pull/2647
* New reference spikes were generated with:
   - NEURON 9.0.a15 (commit=f64b609)
   - py-neurodamus 3.0a1
   - Intel oneAPI Compiler 2022.2.1
   - libsonata-report 1.2.2

**24 Jan 2024**

* Replay with SONATA spike files in all tests
* And update sonataconf-quick-v5-plasticity to use the official circuit_config.json
   - NEURON test with new reference file `v5`
   - Add CoreNEURON test with new reference file `v5`

**10 Oct 2023**

* Updated reference reports for most of  `thalamus`, `hippocampus` and `neocortex` simulations
* New reference files have `v4` in their name
* Was done due to updates in NEURON related to eigen: https://github.com/neuronsimulator/nrn/pull/2470 and https://github.com/neuronsimulator/nrn/pull/2491
   - Branch was created with both changes in order to update the refereces: https://github.com/neuronsimulator/nrn/commits/get_results_from
* New reference spikes were generated with:
   - NEURON 9.0.a8 (commit=3ec979364) - branch mentioned avobe
   - CoreNEURON 9.0.a8 (commit=3ec979364)
   - py-neurodamus 2.16.3
   - Intel oneAPI Compiler 2022.2.1
   - libsonata-report 1.2

**31 May 2023**

* Updated reference reports for `mousify`, `thalamus`, `sonataconf-quick-thalamus`, `multiscale` and `sonataconf-quick-multiscale`
* New reference files have `v3` in their name
* Was done due to updates in `slope_mg` and `scale_mg` variables in https://bbpgitlab.epfl.ch/hpc/sim/models/neocortex/-/merge_requests/16
* Move changes in `slope_mg` and `scale_mg` only to `neocortex`: https://bbpgitlab.epfl.ch/hpc/sim/models/common/-/merge_requests/12
* New reference spikes were generated with:
   - NEURON 9.0.a8 (commit=89f7dab)
   - CoreNEURON 9.0.a8 (commit=89f7dab)
   - py-neurodamus 2.15.0
   - Intel oneAPI Compiler 2022.2.1
   - libsonata-report 1.2

**30 May 2023**

* Updated reference spikes and reports for `scx-1k-v5-newparams`, `quick-1k-v5-nodesets`, `scx-1k-v5`, `scx-2k-v6`, `scx-v5-bonus-minis`, `scx-v5-gapjunctions`, `scx-v5`, `quick-v6`, `scx-v6`, `hip-v6-mcr4`, `quick-hip-delayconn`, `quick-hip-projSeed2`, `hip-v6`, `mousify`, `quick-mousify-sonata`, `sonataconf-quick-scx-multi-circuit`, `quick-v5-gaps`, `sonataconf-quick-v5-plasticity`, `quick-v5-plasticity`, `scx-v5-plasticity`, `sonataconf-quick-thalamus`, `thalamus`, `quick-v5-multisplit`, `multiscale` and `sonataconf-quick-multiscale`
* New reference files have `v2` in their name
* Was done due to setting the modern unit values as default in: https://github.com/BlueBrain/spack/pull/2018
* New reference spikes were generated with:
   - NEURON 9.0.a8 (commit=89f7dab)
   - CoreNEURON 9.0.a8 (commit=89f7dab)
   - py-neurodamus 2.15.0
   - Intel oneAPI Compiler 2022.2.1
   - libsonata-report 1.2

**30 May 2023**

* Updated reference spikes and reports for `scx-v5`, `scx-1k-v5-newparams`, `scx-1k-v5`, `scx-2k-v6`, `scx-v5-plasticity`, `scx-v6`, `quick-v5-multisplit`, `scx-v5-multiplit`, `scx-2k-v6`, `scx-v5-gapjunctions`, `scx-v5-bonus-minis`, `scx-v5-gapjunctions`, `quick-1k-v5-nodesets`, `quick-v5-gaps`, `quick-v5-plasticity`, `sonataconf-quick-scx-multi-circuit`, `sonataconf-quick-v5-plasticity`, `hip-v6`, `hip-v6-mcr4`, `quick-hip-delayconn`, `quick-hip-projSeed2`, `quick-mousify-sonata`, `mousify`, `thalamus`, `sonataconf-quick-thalamus`, `multiscale` and `sonataconf-quick-multiscale`
* New reference files have `v1` in their name
* Was done due to reverting a patch that set certain decimal numbers in a call to Import3d: https://github.com/BlueBrain/spack/pull/2013
* New reference spikes were generated with:
   - NEURON 9.0.a7 (commit=89f7dab)
   - CoreNEURON 9.0.a7 (commit=89f7dab)
   - py-neurodamus 2.15.0
   - Intel oneAPI Compiler 2022.2.1
   - libsonata-report 1.2

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

    export UPDATE_REFERENCE_FILES="ON"
    export REFERENCE_REPORTS_VERSION="<new_version>"

Then for every failure in the comparisons with the reference files the new generated files will be placed in the corresponding place with the name `<report_name><_v$REFERENCE_REPORTS_VERSION><_coreneuron>_<compiler_name>_<compiler_version>_<build_type>.h5`.
For instance:

.. code-block:: bash

    out_v4_coreneuron_oneapi_2022.2.1_FastDebug.h5
    out_v4_oneapi_2022.2.1_FastDebug.h5
    soma_v2_coreneuron_oneapi_2022.2.1_FastDebug.h5
    soma_v2_oneapi_2022.2.1_FastDebug.h5

In addition to this, a new _fasthoc directory is required for the quick-v6 simulation. This can be achieved by loading the local neurodamus used to run these simulations.
This assumes that .test_setup.sh has been sourced:

.. code-block:: bash

    spack load neurodamus-neocortex@develop%oneapi ~plasticity+coreneuron+synapsetool
    hocify /gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-2k/morphologies/ -v --output-dir=/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular/circuit-2k/morphologies/_fasthoc_<new_version>

Subsequently, update the file `quick-v6/test_quick_v6_fasthoc.sh` with the newly generated `_fasthoc` folder.

.. warning::

   !!!BE CAREFULL!!!

   For the report reference files the generated reports are going to be copied to the directory where the current reference reports lie. This is normally in `proj12` directory and GPFS and needs EXTREME CAREFULNESS when happening because this might interfere with all the CIs. The new reference reports will be copied to a file named that encodes whether `coreneuron` was enabled, the compiler name, the compiler version and the build type.

   !!!BE CAREFULL!!!

After doing these changes the changes in the reference files need to be commited in the local git repo of `/gpfs/bbp.cscs.ch/project/proj12/jenkins` and documented in this README.
