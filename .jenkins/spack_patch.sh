# Patch to use a different neurodamus branch
if [ $NEURODAMUS_BRANCH_MASTER ]; then
    sed -i "/master/ s#branch=[^)]*)#branch='$NEURODAMUS_BRANCH_MASTER')#g" \
        ${SPACK_ROOT}/var/spack/repos/builtin/packages/neurodamus-base/package.py
fi
if [ $NEURODAMUS_BRANCH_HIPPOCAMPUS ]; then
    sed -i "/hippocampus/ s#branch=[^)]*)#branch='$NEURODAMUS_BRANCH_HIPPOCAMPUS')#g" \
        ${SPACK_ROOT}/var/spack/repos/builtin/packages/neurodamus-base/package.py
fi
if [ $NEURODAMUS_BRANCH_PLASTICITY ]; then
    sed -i "/plasticity/ s#branch=[^)]*)#branch='$NEURODAMUS_BRANCH_PLASTICITY')#g" \
        ${SPACK_ROOT}/var/spack/repos/builtin/packages/neurodamus-base/package.py
fi

grep version\( ${SPACK_ROOT}/var/spack/repos/builtin/packages/neurodamus-base/package.py
