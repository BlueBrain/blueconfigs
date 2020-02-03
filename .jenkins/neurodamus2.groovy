def TESTS = [
    neocortex: ['scx-v5-gapjunctions', 'scx-2k-v6', 'quick-v5-multisplit'],
    ncx_bare: ['quick-v5-gaps', 'quick-v6'],
    ncx_plasticity: ['scx-v5-plasticity', 'quick-v5-plasticity'],
    hippocampus: ['hip-v6', 'quick-hip-projSeed', 'quick-hip-sonata'],
    thalamus: ['thalamus'],
    mousify: ['quick-mousify-sonata', 'mousify']
]

def run_py_tests() {
    return (GERRIT_PROJECT=="sim/neurodamus-py")? "yes" : "no"
}

def getModel() {
    def parts = GERRIT_PROJECT.split('/')
    if(parts.size() == 3 && parts[1] == "models" && parts[2] != "common") {
        return parts[2]
    }
    return null
}

def setAlternateBranches() {
    def lines = GERRIT_CHANGE_COMMIT_MESSAGE.split('\n')
    def alt_branches=""
    for (line in lines) {
        if (line.contains("_BRANCH=") && !line.startsWith("#")) {
            // Merge them. We later can do a single export
            alt_branches+=line + " "
            // Also set BLUECONFIGS_BRANCH globaly because it's required in Groovy
            if (line.startsWith("BLUECONFIGS")) {
                BLUECONFIGS_BRANCH=line.split("=")[1]
            }
        }
    }
    return alt_branches
}

def findSkipTests() {
    def skip_tests = []
    def lines = GERRIT_CHANGE_COMMIT_MESSAGE.split('\n')
    for (line in lines) {
        if (line.startsWith("SKIP_TEST=")) {
            skip_tests.push(line.split("=")[1])
        }
    }
    return skip_tests
}


pipeline {
    agent { label 'bb5' }

    parameters {
        // Needed to build Gerrit projects
        string(name: 'GERRIT_PROJECT', defaultValue: 'sim/neurodamus-py', description: 'What is the project being changed? (This CI handles all components of neurodamus, inc. neuroamus-core, neurodamus-py and models.    ', )
        string(name: 'GERRIT_REFSPEC', defaultValue: '', description: 'What refspec to fetch for the build (leave empty for standard manual build)', )
        string(name: 'GERRIT_CHANGE_NUMBER', defaultValue: '', description: 'Gerrit change number', )
        string(name: 'ADDITIONAL_ENV_VARS', defaultValue: '', description: 'Additional environment variables that should be exposed to jenkins', )
        string(name: 'GERRIT_CHANGE_COMMIT_MESSAGE', defaultValue: '', description: 'Gerrit commit message to read environment variables to expose to jenkins', )
        string(name: 'BLUECONFIGS_BRANCH', defaultValue: 'master', description: 'Blueconfigs repo branch to use for the tests', )
        string(name: 'SYNAPSETOOL_BRANCH', defaultValue: '', description: 'Synapsetool repo branch to use for the tests', )
        string(name: 'CORENEURON_BRANCH', defaultValue: '', description: 'CoreNeuron repo branch to use for the tests', )
    }

    environment {
        HOME = "${WORKSPACE}/BUILD_HOME"
        SOFTS_DIR_PATH = "${WORKSPACE}/INSTALL_HOME"
        SPACK_INSTALL_PREFIX = "${WORKSPACE}/INSTALL_HOME"
        SPACK_ROOT = "${HOME}/spack"
        PATH = "${SPACK_ROOT}/bin:${PATH}"
        MODULEPATH="${SPACK_INSTALL_PREFIX}/modules/tcl/linux-rhel7-x86_64:${MODULEPATH}"
        RUN_PY_TESTS=run_py_tests()
    }

    stages {
        stage('Setup Spack') {
            steps {
                script {
                    // Checkout blueconfigs
                    alt_branches=setAlternateBranches()
                    checkout(
                        $class: 'GitSCM',
                        userRemoteConfigs: [[
                            url: "ssh://bbpcode.epfl.ch/hpc/blueconfigs",
                            refspec: "+refs/heads/*:refs/remotes/origin/*"
                        ]],
                        branches: [[name: "${BLUECONFIGS_BRANCH}" ]]
                    )
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
                    sh """
                        export ${alt_branches};
                        source ./.tests_setup.sh
                    """

                    // Patch for model or neurodamus core(/py)?
                    if (GERRIT_PROJECT != "sim/models/common") {
                        def sedex = "s#ssh://bbpcode.epfl.ch/${GERRIT_PROJECT}#file://${WORKSPACE}/${GERRIT_PROJECT}#;"
                        sedex += "/tag=/d; s#master#change/${GERRIT_CHANGE_NUMBER}#"
                        def spackfile = "neurodamus-" + (getModel()?: "core")
                        if(GERRIT_PROJECT == "sim/reportinglib/bbp") {
                            spackfile = "reportinglib"
                        } else if(GERRIT_PROJECT == "sim/neurodamus-py") {
                            spackfile = "py-neurodamus"
                        }
                        spackfile = "${SPACK_ROOT}/var/spack/repos/builtin/packages/${spackfile}/package.py"
                        sh """sed -i '${sedex}' '${spackfile}' && grep -n3 'version' '${spackfile}'"""
                    }
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    def model = getModel()
                    def test_pre_init = ""
                    if(GERRIT_PROJECT == "sim/models/common") {
                        test_pre_init += """export ND_VARIANT=' common_mods=${WORKSPACE}/${GERRIT_PROJECT} ';"""
                    }
                    test_pre_init += "export TEST_VERSIONS='" + (model?: TESTS.keySet().join(' ')) + "'"

                    sh """
                        ${test_pre_init}
                        source ./.tests_setup.sh
                        install_neurodamus
                        """
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    def testmap = TESTS
                    def cmds = [:]
                    def model = getModel()
                    def skip_tests = findSkipTests()

                    if(model != null) {
                        // Replace map to have the single entry that matters
                        testmap = [(model): TESTS[model]]
                    }

                    if(GERRIT_PROJECT == "sim/neurodamus-py") {
                        // Dont run save-restore with python yet
                        sh "rm scx-v5-plasticity/test_save-restore_coreneuron.sh"
                    }

                    for (vtests in testmap) {
                        for (testname in vtests.value) {
                            if (skip_tests.contains(testname)) continue
                            def ver = vtests.key
                            def taskname = ver + '-' + testname
                            cmds[taskname] = """
                                source ./.tests_setup.sh
                                run_test ${testname} "\${VERSIONS[$ver]}"
                                """
                        }
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
