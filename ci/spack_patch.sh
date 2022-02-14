[[ -n "$SPACK_ROOT" && -d $SPACK_ROOT ]] || {
    log_error "SPACK_ROOT not set"
    return 1
}
if [ -f $SPACK_ROOT/spack_patched.flag ]; then
    log "Spack installation already Patched (develop branches)"
    return
fi

# Patch to use a different neurodamus branch
sed_apply() {
    local f=$1
    local sedexp=$2
    log "PATCHING $f with '$sedexp'"
    (cd $(dirname $f) && git checkout "$(basename $f)") && sed -i "$sedexp" "$f"
    grep 'version(' "$f"
}


# In the original neurodamus repo there were no tags
# We now have to strip them off as well to avoid using them instead of master
strip_nd_git_tags() (
    nd_projects=(core neocortex hippocampus thalamus mousify)
    for proj in ${nd_projects[@]}; do
        pkg_base=$(spack location -p neurodamus-$proj)
        sedexp='/version.*tag=/d; /version_from_model_.*(/d'

        # change branch if requested
        BVAR="NEURODAMUS_${proj^^}_BRANCH"
        if [ "${!BVAR}" ]; then
            sedexp="$sedexp; s#branch=[^,]*,#branch='${!BVAR}', preferred=True,#g"
            sedexp="$sedexp; s#branch=[^,)]*)#branch='${!BVAR}', preferred=True)#g"
        fi
        sed_apply "${pkg_base}/package.py" "$sedexp"
    done
)

check_patch_project() (
    projname="$1"
    branch="$2"
    if [ "$branch" ]; then
        pkg_base=$(spack location -p $projname)
        sedexp='/version.*tag=/d'  # Drop tags
        sedexp="$sedexp; /version.*commit=/d"  # Drop commits
        sedexp="$sedexp; s#branch=[^),]*\([),]\)#branch='$branch'\1#g" # replace branch
        sed_apply "${pkg_base}/package.py" "$sedexp"
    fi
)

patch_models_common() (
    branch="$1"
    if [ "$branch" ]; then
      # Patch neurodamus-core in case it's installed with "+common" variant
      pkg_base=$(spack location -p neurodamus-core)
      sedexp="s#git=\'git@bbpgitlab.epfl.ch:hpc\/sim\/models\/common.git\',#git=\'git@bbpgitlab.epfl.ch:hpc\/sim\/models\/common.git\',\ branch='$branch',#g"
      sed_apply "${pkg_base}/package.py" "$sedexp"
    fi
)

main()(
    set -e
    log "Patching Spack sources according to required branches..."
    # Generate all modules
    echo "modules:
  tcl:
    naming_scheme: '\${PACKAGE}/\${VERSION}'
    whitelist:
      - '@:'
    " > ${SPACK_ROOT}/etc/spack/modules.yaml

    strip_nd_git_tags

    if [ "${ghprbGhRepository}" = "BlueBrain/CoreNeuron" ] && [ "${ghprbSourceBranch}" ]; then
        CORENEURON_BRANCH="${ghprbSourceBranch}"
        # Temporary fix because current deployed module for NEURON is incompatible with master
        # CoreNEURON
        # TODO: revert back when NEURON is updated to a compatible version with master CoreNEURON
        if [ -z "$NEURON_BRANCH" ]; then
            NEURON_BRANCH="master"
        fi
    fi
    check_patch_project coreneuron "$CORENEURON_BRANCH"
    check_patch_project neuron "$NEURON_BRANCH"

    check_patch_project synapsetool "$SYNAPSETOOL_BRANCH"
    check_patch_project reportinglib "$REPORTINGLIB_BRANCH"
    check_patch_project libsonata-report "$LIBSONATAREPORT_BRANCH"
    check_patch_project py-neurodamus "$PYNEURODAMUS_BRANCH"

    patch_models_common "$MODELS_COMMON_BRANCH"

    touch $SPACK_ROOT/spack_patched.flag
)

main
