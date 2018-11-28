library(identifier: 'bbp@master',
        retriever: modernSCM(
            [$class:'GitSCMSource',
             remote: 'ssh://bbpcode.epfl.ch/hpc/jenkins-pipeline']))

def PACKAGE="neurodamus"
def PACKAGE_DEFAULT_VARIANT = "~coreneuron+syntool+python"
def PACKAGE_COMPILE_OPTIONS ="%intel ^neuron+cross-compile+debug%intel "
def EXTENDED_RESULTS ="/gpfs/bbp.cscs.ch/project/proj12/jenkins/cellular"
def PACKAGES_YAML = "/gpfs/bbp.cscs.ch/project/proj12/jenkins/devel_builds/packages.yaml"
def PARAMS = [
    versions: [
        master: "master",
        master_no_syn2: "master",
        hippocampus: "hippocampus",
        plasticity: "plasticity",
        master_quick: "master"
    ],
    specs: [
        master: PACKAGE_DEFAULT_VARIANT,
        master_no_syn2: "~coreneuron~syntool+python",
        hippocampus: PACKAGE_DEFAULT_VARIANT,
        plasticity: "+coreneuron+syntool+python",
        master_quick: PACKAGE_DEFAULT_VARIANT
    ],
    tests: [
        master: ["scx-v5", "scx-v6", "scx-1k-v5", "scx-2k-v6", "scx-v5-gapjunctions", "scx-v5-bonus-minis", "quick-v5-multisplit"],
        master_no_syn2: ["scx-v5-gapjunctions"],
        hippocampus: ["hip-v6"],
        plasticity: ["scx-v5-plasticity"],
        master_quick: ["quick-v5-gaps", "quick-v6", "quick-v5-multisplit"]
    ]
]


pipeline {
    agent { label 'bb5' }

    parameters {
        string(name: 'GERRIT_REFSPEC', defaultValue: '', description: 'What refspec to fetch for the build (leave empty for standard manual build)', )
        string(name: 'GERRIT_PATCHSET_REVISION', defaultValue: 'master', description: 'Which revision to build (master for standard manual build)', )
        text(name: 'TEST_VERSIONS', defaultValue: "master\nmaster_no_syn2\nhippocampus\nplasticity",
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
        SPACK_ROOT = "${HOME}/spack"
        PATH = "${SPACK_ROOT}/bin:${PATH}"
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
                        def spec = PARAMS.specs[ver] + PACKAGE_COMPILE_OPTIONS
                        def fullspec = "${PACKAGE}@${PARAMS.versions[ver]}${spec}"
                        sh("""
                            source ${WORKSPACE}/.jenkins/envutils.sh
                            set +x
                            echo "INSTALLING ${fullspec}"
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
                        def fullspec = "${PACKAGE}@${PARAMS.versions[ver]}${PARAMS.specs[ver]}"
                        for (name in PARAMS.tests[ver]) {
                            def testname = name
                            def taskname = ver + '-' + name
                            tasks[taskname] = {
                                stage(taskname) {
                                    sh("""
                                        source .jenkins/testutils.sh
                                        run_test ${testname} ${fullspec}
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
