[ -n "$SPACK_SETUP_DONE" ] && return || true

# Patch to use a different neurodamus branch
sed_apply() (
    f=$1
    sedexp=$2
    log "PATCHING $f..."
    (cd $(dirname $f) && git checkout "$(basename $f)") && sed -i "$sedexp" "$f"
    grep 'version(' "$f"
)

# NEURODAMUS branch
sedexp=
if [ $NEURODAMUS_BRANCH_MASTER ]; then
    sedexp="/master/ s#branch=[^)]*)#branch='$NEURODAMUS_BRANCH_MASTER')#g"
fi
if [ $NEURODAMUS_BRANCH_HIPPOCAMPUS ]; then
    sedexp="/hippocampus/ s#branch=[^)]*)#branch='$NEURODAMUS_BRANCH_HIPPOCAMPUS')#g"
fi
if [ $NEURODAMUS_BRANCH_PLASTICITY ]; then
    sedexp="/plasticity/ s#branch=[^)]*)#branch='$NEURODAMUS_BRANCH_PLASTICITY')#g"
fi

[ "$sedexp" ] && sed_apply "${SPACK_ROOT}/var/spack/repos/builtin/packages/neurodamus-base/package.py" "$sedexp"


# In synapsetool we replace version develop and delete all tag versions
if [ $SYNAPSETOOL_BRANCH ]; then
    sedexp="/version..develop/ s#version.*#version('develop', git=url, branch='$SYNAPSETOOL_BRANCH', submodules=True)#;
            /git=url, tag=/ d"
    sed_apply "${SPACK_ROOT}/var/spack/repos/builtin/packages/synapsetool/package.py" "$sedexp"
fi


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
