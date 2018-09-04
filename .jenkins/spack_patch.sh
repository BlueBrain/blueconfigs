# Use develop packages.yaml
cp /gpfs/bbp.cscs.ch/project/proj12/jenkins/devel_builds/packages.yaml $SPACK_ROOT/etc/spack/defaults/linux/

# Patch for modules suffix, otherwise clash
sed -i "s#hash_length: 0#hash_length: 8#g" $SPACK_ROOT/etc/spack/defaults/linux/modules.yaml

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

grep version ${SPACK_ROOT}/var/spack/repos/builtin/packages/neurodamus-base/package.py
