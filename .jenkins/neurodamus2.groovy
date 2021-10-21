def TESTS = [
    neocortex: ['scx-v5-gapjunctions', 'scx-2k-v6', 'quick-v5-multisplit', 'scx-1k-v5', 'scx-1k-v5-newparams', 'scx-v5-bonus-minis'],
    ncx_bare: ['quick-v5-gaps', 'quick-v6', 'point-neuron'],
    ncx_plasticity: ['scx-v5-plasticity', 'quick-v5-plasticity', 'sscx-v7-plasticity'],
    hippocampus: ['hip-v6', 'quick-hip-multipopulation', 'quick-hip-delayconn'],
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
            if (line.startsWith("MODELS_COMMON")) {
                MODELS_COMMON_BRANCH=line.split("=")[1]
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
        string(name: 'SPACK_BRANCH', defaultValue: '', description: 'The spack branch to use', )
        string(name: 'MODELS_COMMON_BRANCH', defaultValue: '', description: 'The common mods branch to use', )
    }

    environment {
        HOME = "${WORKSPACE}/BUILD_HOME"
        PROJECT_DIR = "${WORKSPACE}/${GERRIT_PROJECT}"
        RUN_PY_TESTS = run_py_tests()
        SPACK_ROOT = "${WORKSPACE}/BUILD_HOME/spack"
        TMPDIR = "${TMPDIR}/${BUILD_TAG}"
    }

    stages {

        stage('Setup Spack') {
            steps {
                script {
                    dir(env.TMPDIR) {
                        sh """echo "TMPDIR:"; pwd"""
                    }
                    sh """echo "Current directory:"; pwd; df -h"""

                    // Checkout blueconfigs
                    alt_branches=setAlternateBranches()
                    checkout(
                        $class: 'GitSCM',
                        userRemoteConfigs: [[
                            url: "git@bbpgitlab.epfl.ch:hpc/blueconfigs.git",
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
                    // Use neurodamus upstream to avoid rebuilding core
        /*            if (GERRIT_PROJECT == "sim/neurodamus-py") {
                        sh  """
                            set -x
                            echo "Using Upstream spack neurodamus"
                            upstreams_f="${SPACK_ROOT}/etc/spack/upstreams.yaml"
                            cur_upstreams=\$(tail -n+2 \$upstreams_f)
                            echo "
upstreams:
  neurodamus_spack:
    install_tree: /gpfs/bbp.cscs.ch/project/proj12/builds/neurodamus_spack/opt/spack
    modules:
      tcl: /gpfs/bbp.cscs.ch/project/proj12/builds/neurodamus_spack/share/spack/modules
\$cur_upstreams
" > "\$upstreams_f"
"""
                    }*/

                    // Patch for model or neurodamus core(/py)?
                    if (GERRIT_PROJECT != "sim/models/common") {
                        def sedex = "s#ssh://bbpcode.epfl.ch/${GERRIT_PROJECT}#file://${PROJECT_DIR}#;"
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

        stage('Build & Self Tests') {
        parallel {
            stage('Self Tests') {
                when { expression { fileExists "${PROJECT_DIR}/.jenkins" } }
                steps {
                    script {
                        def cmds = [:]
                        def files = sh(returnStdout: true, script: """find $PROJECT_DIR/.jenkins -type f -name 'test_*.sh'""").split()
                        for (f in files) {
                            def name = '' + f.split("/")[-1].replaceAll(/^test_/, "").replaceAll(/\.sh$/, "")
                            cmds[name] = """unset \$(env|awk -F= '/^(PMI|SLURM)_/ {if (match(\$1, "_(ACCOUNT|PARTITION)\$")==0) print \$1}')
                                            cd "$PROJECT_DIR"
                                            sh ${f}
                                          """;
                        }
                        parallel cmds.collectEntries{
                            key, cmd -> return [(key): { stage(key){sh(cmd)} } ] }
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
                        if(MODELS_COMMON_BRANCH != '') {
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
                        if(model == 'neocortex') {
                            test_pre_init += "export TEST_VERSIONS='ncx_bare ncx_plasticity neocortex'"
                        } else {
                            test_pre_init += "export TEST_VERSIONS='" + (model?: TESTS.keySet().join(' ')) + "'"
                        }
                        if (GERRIT_PROJECT == "sim/neurodamus-py") {
                            sh """
                                source ./.tests_setup.sh
                                install_neurodamus
                                spack install py-neurodamus+all_deps
                            """
                        } else {
                            sh """
                                ${test_pre_init}
                                source ./.tests_setup.sh
                                install_neurodamus
                            """
                        }
                    }
                }
            }
        }}

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
                        if(model == 'neocortex') {
                            testmap += [('ncx_bare'): TESTS['ncx_bare']]
                            testmap += [('ncx_plasticity'): TESTS['ncx_plasticity']]
                        }
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
            dir(env.TMPDIR) {
                deleteDir()
            }
        }
    }
}
