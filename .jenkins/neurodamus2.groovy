def TESTS = [
    neocortex: ['quick-v5-gaps', 'quick-v6', 'quick-v5-multisplit'],
    ncx_bare: ['quick-v5-gaps', 'quick-v6'],
    hippocampus: ['hip-v6'],
    thalamus: ['thalamus'],
    mousify: ['mousify']
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

def getBlueconfigsBranch() {
    def parts = GERRIT_CHANGE_COMMIT_MESSAGE.split()
    def len = parts.length
    for (i = 0; i < len; i++) {
        item = parts[i]
        if (item == "BLUECONFIGS_BRANCH") {
            BLUECONFIGS_BRANCH = parts[i+2]
            break
        }
    }
}


pipeline {
    agent { label 'bb5' }

    parameters {
        // Needed to build Gerrit projects
        string(name: 'GERRIT_PROJECT', defaultValue: 'sim/neurodamus-py', description: 'What is the project being changed? (This CI handles all components of neurodamus, inc. neuroamus-core, neurodamus-py and models.	', )
        string(name: 'GERRIT_REFSPEC', defaultValue: '', description: 'What refspec to fetch for the build (leave empty for standard manual build)', )
        string(name: 'GERRIT_CHANGE_NUMBER', defaultValue: '', description: 'Gerrit change number', )
        string(name: 'ADDITIONAL_ENV_VARS', defaultValue: '', description: 'Additional environment variables that should be exposed to jenkins', )
        string(name: 'GERRIT_CHANGE_COMMIT_MESSAGE', defaultValue: '', description: 'Gerrit commit message to read environment variables to expose to jenkins', )
        string(name: 'BLUECONFIGS_BRANCH', defaultValue: 'master', description: 'Blueconfigs repo branch to use for the tests', )
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
                    getBlueconfigsBranch()
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
                    sh "source ./.tests_setup.sh"

                    // Patch for model or neurodamus core(/py)?
                    def model = getModel()
                    def sedex = "s#ssh://bbpcode.epfl.ch/${GERRIT_PROJECT}#file://${WORKSPACE}/${GERRIT_PROJECT}#;"
                    if (model != null || GERRIT_PROJECT == 'sim/neurodamus-core') {
                        sedex += "/tag=/d; s#master#change/${GERRIT_CHANGE_NUMBER}#"
                    }
                    def corefile = "${SPACK_ROOT}/var/spack/repos/builtin/packages/neurodamus-${model?:'core'}/package.py"
                    sh "sed -i '${sedex}' ${corefile} && grep -n3 'git=' ${corefile}"
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    def model = getModel()
                    def test_pre_init = ""
                    if(GERRIT_PROJECT == "sim/models/common") {
                        test_pre_init = """export ND_VARIANT=' common_mods=${WORKSPACE}/${GERRIT_PROJECT} '"""
                    }
                    test_pre_init += "\nexport TEST_VERSIONS='" + (model?: TESTS.keySet().join(' ')) + "'"

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
                    if(model != null) {
                        // Replace map to have the single entry that matters
                        testmap = [(model): TESTS[model]]
                    }
                    for (vtests in testmap) {
                        for (testname in vtests.value) {
                            def ver = vtests.key
                            def taskname = ver + '-' + testname
                            cmds[taskname] = """
                                source ./.tests_setup.sh
                                run_test ${testname} \${VERSIONS[$ver]}
                                """
                        }
                    }
                    // PLASTICITY - Build and Run independent and in parallel
                    if (model == null) {
                        test_pre_init = "export TEST_VERSIONS=ncx_plasticity"
                        if(GERRIT_PROJECT == "sim/models/common") {
                            test_pre_init += """\nexport ND_VARIANT=' common_mods=${WORKSPACE}/${GERRIT_PROJECT} '"""
                        }
                        cmds['plasticity'] = """
                            ${test_pre_init}
                            source ./.tests_setup.sh
                            install_neurodamus
                            run_all_tests
                        """
                        // Dont run save-restore with python yet
                        sh "rm scx-v5-plasticity/test_save-restore_coreneuron.sh"
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