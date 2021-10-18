library(identifier: 'bbp@master',
        retriever: modernSCM(
            [$class:'GitSCMSource',
             remote: 'ssh://bbpcode.epfl.ch/hpc/jenkins-pipeline']))

def PARAMS = [
    tests: [
        neocortex:      ["scx-v5", "scx-v6", "scx-1k-v5", "scx-2k-v6", "scx-v5-gapjunctions",
                         "scx-v5-bonus-minis", "quick-v5-multisplit", "scx-1k-v5-newparams",
                         "quick-1k-v5-nodesets", "quick-scx-multi-circuit"],
        ncx_bare:       ["quick-v5-gaps", "quick-v6", "quick-v5-multisplit", "point-neuron"],
        ncx_plasticity: ["scx-v5-plasticity", "quick-v5-plasticity"],
        hippocampus:    ["hip-v6", "hip-v6-mcr4", "quick-hip-projSeed2", "quick-hip-multipopulation", "quick-hip-delayconn"],
        thalamus:       ["thalamus"],
        mousify:        ["quick-mousify-sonata", "mousify"]
    ],
    test_groups: [
        ['ncx_bare'],
        ['neocortex'],
        ['ncx_plasticity', 'hippocampus', 'thalamus', 'mousify']
    ],
    long_run_tests: [
        ncx_plasticity: [testname:'scx-v5-plasticity', target:'mc0_Column'],
        hippocampus: [testname: 'quick-hip-multipopulation', target: 'hippocampus_neurons:Mosaic'],
        mousify: [testname: 'mousify', target: 'Layer45'],
        thalamus: [testname: 'thalamus', target: 'Mosaic']
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

def setAlternateBranches() {
    def alt_branches=""
    def description = ""
    if (env.gitlabSourceRepoName && env.gitlabSourceRepoName == "blueconfigs") {
        if (env.gitlabMergeRequestDescription && env.gitlabMergeRequestDescription != "") {
            description = env.gitlabMergeRequestDescription
        }
    } else if (env.ghprbGhRepository && env.ghprbGhRepository == "BlueBrain/CoreNeuron" && env.ghprbSourceBranch != "" && env.ghprbPullLongDescription != "") {
        description = env.ghprbPullLongDescription
    }
    if (description.contains('CI_BRANCHES:')) {
        ci_branches = description.split('CI_BRANCHES:')
        branches = ci_branches[1].split(',')
        for (branch in branches) {
            if (branch.contains("_BRANCH=")) {
                // Merge them. We later can do a single export
                alt_branches+=branch + " "
            }
            if (branch.startsWith("MODELS_COMMON")) {
                env.MODELS_COMMON_BRANCH=branch.split("=")[1]
            }
        }
    }
    return alt_branches
}

pipeline {
    agent { label 'bb5' }

    parameters {
        text(name: 'TEST_VERSIONS',
             defaultValue: "neocortex\nncx_bare\nncx_plasticity\nhippocampus\nthalamus\nmousify",
             description: 'Which version of the package to build & test.')
        string(name: 'SPACK_BRANCH', defaultValue: '',
               description: 'Which branch of spack to use for the build.')
        string(name: 'CORENEURON_BRANCH', defaultValue: '',
               description: 'Which branch of coreneuron to use for the build.')
        string(name: 'NEURON_BRANCH', defaultValue: '',
               description: 'Which branch of neuron to use for the build.')
        string(name: 'MODELS_COMMON_BRANCH', defaultValue: '',
               description: 'The common mods branch to use', )
        string(name: 'RUN_PY_TESTS', defaultValue: 'yes',
               description: 'Run tests with Python Neurodamus')
        string(name: 'RUN_HOC_TESTS', defaultValue: 'yes',
               description: 'Run tests with HOC Neurodamus')
        string(name: 'DRY_RUN', defaultValue: '',
               description: 'Will start a DRY_RUN, i.e. dont run sims, mostly to test CI itself')
        string(name: 'ADDITIONAL_ENV_VARS', defaultValue: '',
               description: 'Provide additional environment vars. E.g NEURODAMUS_BRANCH_MASTER=x')
        string(name: 'LONG_RUN', defaultValue: '',
               description: 'RUN weekly large simulation tests with Python Neuromdamus')
        string(name: 'SKIP_DAILY_TESTS', defaultValue: 'no',
               description: 'Skip daily tests (mostly for debugging long tests)')
        string(name: 'BASH_TRACE', defaultValue: 'no',
               description: 'Activate Bash trace for debugging')
        string(name: 'gitlabSourceBranch', defaultValue: 'master',
               description: 'Which branch from gitlab to build (master for standard manual build)')
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
        MODULEPATH = "${SPACK_INSTALL_PREFIX}/modules/tcl/linux-rhel7-x86_64:${MODULEPATH}"
        TMPDIR = "${TMPDIR}/${BUILD_TAG}"
        LONG_RUN = run_long_test()
    }

    stages {
        stage("Setup Spack") {
            steps {
                script {
                    alt_branches=setAlternateBranches()
                    sh("""export ${alt_branches};
                          source ${WORKSPACE}/.tests_setup.sh
                          mkdir ${TMPDIR}
                          echo "LONG_RUN="$LONG_RUN
                       """
                    )
                }
            }
        }
        stage('Build') {
            steps {
                script {
                    def test_versions = env.TEST_VERSIONS.tokenize('\n')
                    if( env.ghprbGhRepository == "BlueBrain/CoreNeuron" ) {
                        test_versions = ['ncx_plasticity', 'hippocampus', 'thalamus']
                    }
                    def test_pre_init = ""
                    if( env.MODELS_COMMON_BRANCH != '' ) {
                        // Clone and use certain common models branch for neurodamus-models
                        def common_mods_dir = "${TMPDIR}/common"
                        dir(common_mods_dir) {
                            checkout(
                                $class: 'GitSCM',
                                userRemoteConfigs: [[
                                    url: "ssh://bbpcode.epfl.ch/sim/models/common",
                                    refspec: "+refs/heads/*:refs/remotes/origin/*"
                                ]],
                                branches: [[name: "${MODELS_COMMON_BRANCH}" ]]
                            )
                        }
                        test_pre_init += """export ND_VARIANT=' common_mods=${common_mods_dir} ';"""
                    }
                    for (ver in test_versions) {
                        sh("""${test_pre_init}
                              source ${WORKSPACE}/.tests_setup.sh
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
        stage('Tests') {
            when {
                expression { return env.SKIP_DAILY_TESTS == 'no' }
            }
            steps {
                script {
                    def test_versions = env.TEST_VERSIONS.tokenize('\n')
                    if( env.ghprbGhRepository == "BlueBrain/CoreNeuron" ) {
                        test_versions = ['ncx_plasticity', 'hippocampus', 'thalamus']
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
                            }
                        }
                        parallel tasks
                    }
                }
            }
        }
        stage('Long Tests') {
            when {
                expression { env.LONG_RUN == 'yes' }
            }
            steps {
                script{
                    def tasks = [:]
                    for (version in PARAMS.long_run_tests.keySet()) {
                        def conf = PARAMS.long_run_tests[version]
                        def testname = conf.testname
                        def taskname = version + '-' + testname
                        def target = conf.target
                        def v = version
                        tasks[taskname] = {
                            stage(taskname) {
                                sh("""source ${WORKSPACE}/.tests_setup.sh
                                      source ${WORKSPACE}/.jenkins/longrun.sh
                                      run_long_test ${testname} "\${VERSIONS[$v]}" ${target}
                                    """
                                )
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
        failure {
            script{
                if (currentBuild.getBuildCauses()[0].shortDescription.contains("GitLab")){
                    updateGitlabCommitStatus name: 'jenkins', state: 'failed'
                }
            }
        }
        success {
            script{
                if (currentBuild.getBuildCauses()[0].shortDescription.contains("GitLab")){
                    updateGitlabCommitStatus name: 'jenkins', state: 'success'
                }
            }
        }
        aborted {
            script{
                if (currentBuild.getBuildCauses()[0].shortDescription.contains("GitLab")){
                    updateGitlabCommitStatus name: 'jenkins', state: 'canceled'
                }
            }
        }
    }
}
