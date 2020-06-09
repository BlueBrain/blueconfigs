library(identifier: 'bbp@master',
        retriever: modernSCM(
            [$class:'GitSCMSource',
             remote: 'ssh://bbpcode.epfl.ch/hpc/jenkins-pipeline']))

def PARAMS = [
    tests: [
        neocortex:      ["scx-v5", "scx-v6", "scx-1k-v5", "scx-2k-v6", "scx-v5-gapjunctions",
                         "scx-v5-bonus-minis", "quick-v5-multisplit"],
        ncx_bare:       ["quick-v5-gaps", "quick-v6", "quick-v5-multisplit"],
        ncx_plasticity: ["scx-v5-plasticity", "quick-v5-plasticity"],
        hippocampus:    ["hip-v6", "hip-v6-mcr4", "quick-hip-sonata", "quick-hip-projSeed"],
        thalamus:       ["thalamus"],
        mousify:        ["quick-mousify-sonata", "mousify"]
    ],
    test_groups: [
        ['ncx_bare'],
        ['neocortex'],
        ['ncx_plasticity', 'hippocampus', 'thalamus', 'mousify']
    ],
    alternate: [
        // Run again some tests with diff configs
        ncx_bare: [version:'neocortex', env:'RUN_PY_TESTS=yes', tag:'PYTHON']
    ],
    long_run_tests: [
        neocortex:[
//             [testname:'scx-v5', target: 'Mosaic'],
            [testname:'scx-v6', target: 'Mosaic'],
            [testname:'scx-v5-gapjunctions', target: 'Mosaic'],
            [testname:'scx-v5-bonus-minis', target: 'Mosaic'],
//             [testname:'quick-v5-multisplit',target: 'Mosaic']
        ],
//         ncx_plasticity: [
//             [testname:'scx-v5-plasticity', target:'Mosaic']
//         ],
        hippocampus: [
//             [testname:'hip-v6', target:'Mosaic'],
            [testname:'hip-v6-mcr4', target:'Mosaic']
//             [testname:'quick-hip-sonata', target:'Mosaic'],
//             [testname:'quick-hip-projSeed', target:'Mosaic']
        ],
        thalamus:[
            [testname:'thalamus', target:'Mosaic']
        ]
//         mousify: [
//             [testname:'mousify', target:'Mosaic']
//         ]
    ]
]

def run_long_test() {
    if (env.LONG_RUN) {
        return env.LONG_RUN
    } else {
        def buildCause = currentBuild.getBuildCauses()[0].shortDescription
        Calendar myDate = Calendar.getInstance()
        def isSunday = myDate.get(Calendar.DAY_OF_WEEK) == Calendar.SUNDAY
        return (isSunday && buildCause.contains("Started by timer")) ? "yes" : "no"
    }
}

pipeline {
    agent { label 'bb5' }

    parameters {
        string(name: 'GERRIT_REFSPEC', defaultValue: '',
               description: 'What refspec to fetch for the build (leave empty for standard manual build)', )
        string(name: 'GERRIT_PATCHSET_REVISION', defaultValue: 'master',
               description: 'Which revision to build (master for standard manual build)')
        text(name: 'TEST_VERSIONS',
             defaultValue: "neocortex\nncx_bare\nncx_plasticity\nhippocampus\nthalamus\nmousify",
             description: 'Which version of the package to build & test.')
        string(name: 'SPACK_BRANCH', defaultValue: '',
               description: 'Which branch of spack to use for the build.')
        string(name: 'CORENEURON_BRANCH', defaultValue: '',
               description: 'Which branch of coreneuron to use for the build.')
        string(name: 'RUN_PY_TESTS', defaultValue: 'no',
               description: 'Run tests with Python Neurodamus, or plain hoc')
        string(name: 'DRY_RUN', defaultValue: '',
               description: 'Will start a DRY_RUN, i.e. dont run sims, mostly to test CI itself')
        string(name: 'ADDITIONAL_ENV_VARS', defaultValue: '',
               description: 'Provide additional environment vars. E.g NEURODAMUS_BRANCH_MASTER=x')
        string(name: 'GERRIT_CHANGE_COMMIT_MESSAGE', defaultValue: '')
        string(name: 'LONG_RUN', defaultValue: '',
               description: 'RUN weekly large simulation tests with Python Neuromdamus')

    }

//     triggers {
//         cron('H H(0-6) * * *')
//     }

    environment {
        DATADIR = "/gpfs/bbp.cscs.ch/project/proj12/jenkins"
        HOME = "${WORKSPACE}/BUILD_HOME"
        SOFTS_DIR_PATH = "${WORKSPACE}/INSTALL_HOME"
        SPACK_INSTALL_PREFIX = "${WORKSPACE}/INSTALL_HOME"
        SPACK_ROOT = "${HOME}/spack"
        PATH = "${SPACK_ROOT}/bin:${PATH}"
        MODULEPATH = "${SPACK_INSTALL_PREFIX}/modules/tcl/linux-rhel7-x86_64:${MODULEPATH}"
        TMPDIR = "${TMPDIR}/${BUILD_TAG}"
        LONG_RUN = run_long_test()
    }

    stages {
        stage("Setup Spack") {
            steps {
                sh '''source ${WORKSPACE}/.tests_setup.sh
                      mkdir ${TMPDIR}
                      echo "LONG_RUN="$LONG_RUN
                   '''
            }
        }
        stage('Build') {
            steps {
                script {
                    def test_versions = env.TEST_VERSIONS.tokenize('\n')
                    if( env.ghprbGhRepository == "BlueBrain/CoreNeuron" ) {
                        test_versions = ['ncx_plasticity']
                    }
                    for (ver in test_versions) {
                        sh("""source ${WORKSPACE}/.tests_setup.sh
                              install_neurodamus ${ver}
                            """
                        )
                    }
                }
            }
        }
        stage('DRY_RUN Exec') {
            when {
                expression { return env.DRY_RUN }
            }
            steps {
                sh '''unset DRY_RUN
                      source ${WORKSPACE}/.tests_setup.sh
                      install_neurodamus ncx_bare
                      run_test_debug quick-v5-gaps "\${VERSIONS[ncx_bare]}"
                    '''
            }
        }
        stage('Test') {
            when {
                expression { env.LONG_RUN != 'yes' }
            }
            steps {
                script {
                    def test_versions = env.TEST_VERSIONS.tokenize('\n')
                    if( env.ghprbGhRepository == "BlueBrain/CoreNeuron" ) {
                        test_versions = ['ncx_plasticity']
                    }
                    for (group in PARAMS.test_groups) {
                        def tasks = [:]
                        for (ver in test_versions) {
                            if( ! group.contains(ver) ) {
                                continue
                            }
                            for (name in PARAMS.tests[ver]) {
                                def testname = name
                                def taskname = ver + '-' + name
                                def v = ver
                                tasks[taskname] = {
                                    stage(taskname) {
                                        sh("""source ${WORKSPACE}/.tests_setup.sh
                                              run_test ${testname} "\${VERSIONS[$v]}"
                                             """
                                        )
                                    }
                                }
                                if(PARAMS.alternate.containsKey(ver)) {
                                    def conf=PARAMS.alternate[ver]
                                    def v2 = conf.version
                                    def taskname2 = conf.tag + '_' + v2 + '-' + name
                                    tasks[taskname2] = {
                                        stage(taskname2) {
                                            sh("""export ${conf.get('env', '')}
                                                  source ${WORKSPACE}/.tests_setup.sh
                                                  run_test ${testname} "\${VERSIONS[$v2]}"
                                                 """
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        parallel tasks
                    }
                }
            }
        }
        stage('LONG_RUN') {
            when {
                expression { env.LONG_RUN == 'yes' }
            }
            steps {
                script{
                    def tasks = [:]
                    for (version in PARAMS.long_run_tests.keySet()) {
                        for (conf in PARAMS.long_run_tests[version]) {
                            def testname = conf.testname
                            def taskname = version + '-' + testname
                            def target = conf.target
                            def v = version
                            tasks[taskname] = {
                                stage(taskname) {
                                    sh("""source ${WORKSPACE}/.tests_setup.sh
                                          source ${WORKSPACE}/.jenkins/longrun.sh
                                          RUN_PY_TESTS=yes run_long_test ${testname} "\${VERSIONS[$v]}" ${target}
                                          RUN_PY_TESTS=no run_long_test ${testname} "\${VERSIONS[$v]}" ${target}

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
            dir(env.TMPDIR) {
                deleteDir()
            }
        }
    }
}
