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
