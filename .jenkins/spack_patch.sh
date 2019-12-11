[ -f spack_patched.flag ] && return || log "Patching spack packages source"

PKGS_BASE="${SPACK_ROOT}/var/spack/repos/builtin/packages"


# Patch to use a different neurodamus branch
sed_apply() (
    f=$1
    sedexp=$2
    log "PATCHING $f with '$sedexp'"
    (cd $(dirname $f) && git checkout "$(basename $f)") && sed -i "$sedexp" "$f"
    grep 'version(' "$f"
)


# In the original neurodamus repo there were no tags
# We now have to strip them off as well to avoid using them instead of master
strip_nd_git_tags() (
    nd_projects=(core neocortex hippocampus thalamus mousify)
    for proj in ${nd_projects[@]}; do
        pkg_file="$PKGS_BASE/neurodamus-$proj/package.py"
        sedexp='/version.*tag=/d'

        # change branch if requested
        BVAR="NEURODAMUS_BRANCH_${proj^^}"
        if [ "${!BVAR}" ]; then
            sedexp="$sedexp; s#branch=[^)]*)#branch='${!BVAR}')#g"
        fi
        sed_apply "$pkg_file" "$sedexp"
    done
)

check_patch_coreneuron() (
    # Coreneuron doesnt typically use branches, we add it.
    sedexp=
    if [ $CORENEURON_BRANCH ]; then
        sedexp="s#git=url#git=url, branch='$CORENEURON_BRANCH'#g"
    fi
    if [ $CORENEURON_BRANCH_PLASTICITY ]; then
        sedexp="/plasticity/ s#git=url#git=url, branch='$CORENEURON_BRANCH_PLASTICITY'#g"
    fi
    if [ "$sedexp" ]; then
        sed_apply "${SPACK_ROOT}/var/spack/repos/builtin/packages/coreneuron/package.py" "$sedexp"
    fi
)

check_patch_project() (
    projname="$1"
    branch="$2"
    if [ "$branch" ]; then
        pkg_file="$PKGS_BASE/$projname/package.py"
        sedexp='/version.*tag=/d'  # Drop tags
        sedexp="$sedexp; s#branch=[^)]*)#branch='$branch')#g"  # replace branch
        sed_apply "$pkg_file" "$sedexp"
    fi
)


main()(
    set -e
    strip_nd_git_tags
    check_patch_coreneuron
    check_patch_project synapsetool "$SYNAPSETOOL_BRANCH"
    check_patch_project reportinglib "$REPORTINGLIB_BRANCH"
    touch spack_patched.flag
)

main
