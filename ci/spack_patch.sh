[ -f spack_patched.flag ] && return || log "Patching spack packages source"

PKGS_BASE="${SPACK_ROOT}/var/spack/repos/builtin/packages"


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
        pkg_file="$PKGS_BASE/neurodamus-$proj/package.py"
        sedexp='/version.*tag=/d; /version_from_model_core_deps(/d'

        # change branch if requested
        BVAR="NEURODAMUS_${proj^^}_BRANCH"
        if [ "${!BVAR}" ]; then
            sedexp="$sedexp; s#branch=[^,]*,#branch='${!BVAR}', preferred=True,#g"
            sedexp="$sedexp; s#branch=[^,)]*)#branch='${!BVAR}', preferred=True)#g"
        fi
        sed_apply "$pkg_file" "$sedexp"
    done
)

check_patch_project() (
    projname="$1"
    branch="$2"
    if [ "$branch" ]; then
        pkg_file="$PKGS_BASE/$projname/package.py"
        sedexp='/version.*tag=/d'  # Drop tags
        sedexp="$sedexp; /version.*commit=/d"  # Drop commits
        sedexp="$sedexp; s#branch=[^)]*)#branch='$branch', preferred=True)#g"  # replace branch
        sed_apply "$pkg_file" "$sedexp"
    fi
)

patch_models_common() (
    branch="$1"
    if [ "$branch" ]; then
      # Patch neurodamus-core in case it's installed with "+common" variant
      sedexp="s#git=\'ssh:\/\/bbpcode.epfl.ch\/sim\/models\/common\',#git=\'ssh:\/\/bbpcode.epfl.ch\/sim\/models\/common\',\ branch='$branch',#g"
      sed_apply "$PKGS_BASE/neurodamus-core/package.py" "$sedexp"
    fi
)

main()(
    set -e
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
    check_patch_project py-neurodamus "$PYNEURODAMUS_BRANCH"

    patch_models_common "$MODELS_COMMON_BRANCH"

    touch spack_patched.flag
)

main