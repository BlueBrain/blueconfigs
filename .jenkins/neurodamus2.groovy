def VERSIONS_SPEC = [
    neocortex: 'neurodamus-neocortex+coreneuron+synapsetool',
    ncx_bare: 'neurodamus-neocortex~coreneuron~synapsetool',
    hippocampus: 'neurodamus-hippocampus',
    thalamus: 'neurodamus-thalamus'
]

def TESTS = [
    neocortex: ['quick-v5-gaps', 'quick-v6', 'quick-v5-multisplit'],
    ncx_bare: ['quick-v5-gaps', 'quick-v6'],
    hippocampus: ['hip-v6'],
    thalamus: ['thalamus']
]

def CUSTOM_TESTS = [
    plasticity_CoreNeuron: """
        source ./.tests_setup.sh
        export TEST_VERSIONS=ncx_plasticity
        install_neurodamus
        run_all_tests
        """
]


def run_py_tests() {
    return (GERRIT_PROJECT=="sim/neurodamus-py")? "yes" : "no"
}

def getModel() {
    def parts = GERRIT_PROJECT.split('/')
    if(parts.size() == 3 && parts[1] == "models") {
        return parts[2]
    }
    return null
}


pipeline {
    agent { label 'bb5' }

    environment {
        HOME = "${WORKSPACE}/BUILD_HOME"
        SOFTS_DIR_PATH = "${WORKSPACE}/INSTALL_HOME"
        SPACK_INSTALL_PREFIX = "${WORKSPACE}/INSTALL_HOME"
        SPACK_ROOT = "${HOME}/spack"
        TEST_VERSIONS="ncx_bare neocortex hippocampus thalamus"
        PATH = "${SPACK_ROOT}/bin:${PATH}"
        MODULEPATH="${SPACK_INSTALL_PREFIX}/modules/tcl/linux-rhel7-x86_64:${MODULEPATH}"
        RUN_PY_TESTS=run_py_tests()
    }

    stages {
        stage('Setup Spack') {
            steps {
                script {
                    // Checkout blueconfigs
                    git url: 'ssh://bbpcode.epfl.ch/hpc/blueconfigs'

                    // Checkout the gerrit project being changed
                    dir(GERRIT_PROJECT) {
                        checkout(
                            $class: 'GitSCM',
                            userRemoteConfigs: [[
                                url: "ssh://bbpcode.epfl.ch/${GERRIT_PROJECT}",
                                refspec: GERRIT_REFSPEC + ":refs/heads/change/" +  GERRIT_CHANGE_NUMBER
                            ]],
                            branches: [[name: "change/${GERRIT_CHANGE_NUMBER}" ]]
                        )
                    }

                    // Init spack
                    sh "source .jenkins/spack_setup.sh"

                    // Patch for model or neurodamus core(/py)?
                    def proj = getModel()?: "core"
                    def sedex = "s#ssh://bbpcode.epfl.ch/${GERRIT_PROJECT}#file://${WORKSPACE}/${GERRIT_PROJECT}#;"
                    if(GERRIT_PROJECT != "sim/neurodamus-py") {
                        sedex += "/tag=/d; s#master#change/${GERRIT_CHANGE_NUMBER}#"
                    }
                    def corefile = "${SPACK_ROOT}/var/spack/repos/builtin/packages/neurodamus-${proj}/package.py"
                    sh "sed -i '${sedex}' ${corefile} && grep -n3 ${GERRIT_PROJECT} ${corefile}"
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    def model = getModel()
                    def test_override = ""
                    if(model != null) {
                        test_override = "export TEST_VERSIONS=" + model
                    }
                    sh """
                        source ./.tests_setup.sh
                        ${test_override}
                        install_neurodamus
                        """
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    def cmds = [:]
                    def model = getModel()
                    if(model != null) {
                        // Replace map to have the single entry that matters
                        VERSIONS_SPEC = [(model): VERSIONS_SPEC[model]]
                    }
                    for (vspec in VERSIONS_SPEC) {
                        for (testname in TESTS[vspec.key]) {
                            def taskname = "${vspec.key}-${testname}"
                            cmds[taskname] = """
                                source .jenkins/testutils.sh
                                run_test ${testname} ${vspec.value}
                                """.toString()
                        }
                    }
                    if (model == null) {
                        cmds << CUSTOM_TESTS
                    }
                    parallel cmds.collectEntries{
                        key, cmd -> return [(key): { stage(key){sh(cmd)} } ] }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
