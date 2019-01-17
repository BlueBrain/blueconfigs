library(identifier: 'bbp@master',
        retriever: modernSCM(
            [$class:'GitSCMSource',
             remote: 'ssh://bbpcode.epfl.ch/hpc/jenkins-pipeline']))

def PACKAGE_COMPILE_OPTIONS ="^neuron+cross-compile+debug"
def CORENRN_DEP = "^coreneuron+debug"
def EXTENDED_RESULTS ="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular"
def PACKAGES_YAML = "/gpfs/bbp.cscs.ch/project/proj12/jenkins/devel_builds/packages.yaml"
def PARAMS = [
    versions: [
        master:      "neurodamus-neocortex@develop%intel"   + "~plasticity+coreneuron+synapsetool" + CORENRN_DEP,
        master_no_syn2: "neurodamus-neocortex@develop%intel"   + "~plasticity~coreneuron~synapsetool",
        plasticity:  "neurodamus-neocortex@develop%intel"   + "+plasticity+coreneuron+synapsetool" + CORENRN_DEP,
        hippocampus: "neurodamus-hippocampus@develop%intel" + "~coreneuron+synapsetool",
    ],
    tests: [
        master:       ["scx-v5", "scx-v6", "scx-1k-v5", "scx-2k-v6", "scx-v5-gapjunctions", "scx-v5-bonus-minis", "quick-v5-multisplit"],
        master_no_syn2:  ["quick-v5-gaps", "quick-v6", "quick-v5-multisplit"],
        plasticity:   ["scx-v5-plasticity"],
        hippocampus:  ["hip-v6"],
    ]
]


pipeline {
    agent { label 'bb5' }

    parameters {
        string(name: 'GERRIT_REFSPEC', defaultValue: '', description: 'What refspec to fetch for the build (leave empty for standard manual build)', )
        string(name: 'GERRIT_PATCHSET_REVISION', defaultValue: 'master', description: 'Which revision to build (master for standard manual build)', )
        text(name: 'TEST_VERSIONS', defaultValue: "master_no_syn2\nmaster\nhippocampus\nplasticity",
             description: 'Which version of the package to build & test.' )
        string(name: 'SPACK_BRANCH', defaultValue: 'develop', description: 'Which branch of spack to use for the build.', )
        string(name: 'RUN_PY_TESTS', defaultValue: 'no', description: 'Run tests with Python Neurodamus, or plain hoc')
        string(name: 'ADDITIONAL_ENV_VARS', defaultValue: '', description: 'Provide additional environment vars. E.g NEURODAMUS_BRANCH_MASTER=x')
        string(name: 'GERRIT_CHANGE_COMMIT_MESSAGE', defaultValue: '')
    }

    triggers {
        cron('H H(0-6) * * *')
    }

    environment {
        DATADIR = "/gpfs/bbp.cscs.ch/project/proj12/jenkins"
        HOME = "${WORKSPACE}/BUILD_HOME"
        SOFTS_DIR_PATH = "${WORKSPACE}/INSTALL_HOME"
        SPACK_INSTALL_PREFIX = "${WORKSPACE}/INSTALL_HOME"
        SPACK_ROOT = "${HOME}/spack"
        PATH = "${SPACK_ROOT}/bin:${PATH}"
        MODULEPATH="${SPACK_INSTALL_PREFIX}/modules/tcl/linux-rhel7-x86_64:${MODULEPATH}"
    }

    stages {
        stage("Setup Spack") {
            steps {
                sh("source .jenkins/spack_setup.sh")
            }
        }
        stage('Build') {
            steps {
                script {
                    def test_versions = env.TEST_VERSIONS.tokenize('\n')
                    for (ver in test_versions) {
                        def fullspec = "${PARAMS.versions[ver]}" + PACKAGE_COMPILE_OPTIONS
                        sh("""
                            source ${WORKSPACE}/.jenkins/envutils.sh
                            set +x
                            echo "\n\nINSTALLING ${fullspec} (ver=$ver)"
                            source ${SPACK_ROOT}/share/spack/setup-env.sh
                            spack install --show-log-on-error $fullspec
                            """
                        )
                    }
                }
            }
        }
        stage('Test') {
            steps {
                script {
                    def tasks = [:]
                    def test_versions = env.TEST_VERSIONS.tokenize('\n')
                    for (ver in test_versions) {
                        def spec = "${PARAMS.versions[ver]}"
                        for (name in PARAMS.tests[ver]) {
                            def testname = name
                            def taskname = ver + '-' + name
                            tasks[taskname] = {
                                stage(taskname) {
                                    sh("""
                                        source .jenkins/testutils.sh
                                        run_test ${testname} ${spec}
                                        """
                                    )
                                }
                            }
                        }
                    }
                    parallel tasks
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
