[[ -n "$SPACK_ROOT" && -d $SPACK_ROOT ]] || {
    log_error "SPACK_ROOT not set"
    return 1
}
if [ -f $SPACK_ROOT/spack_patched.flag ]; then
    log "Spack installation already Patched (develop branches)"
    return
fi

main()(
    set -e

    if [ ! "$CI_JOB_ID" ]; then
      log "Patching Spack sources according to required branches... (non-ci run)"
      export PY_NEURODAMUS_BRANCH=${PY_NEURODAMUS_BRANCH:-main}
      env -0 | sed -nz '/^CUSTOM_ENV_/d;/^[^=]\+_\(BRANCH\|COMMIT\|TAG\)=.\+/p' | xargs -0t spack configure-pipeline --ignore-packages CI_COMMIT CI_DEFAULT SPACK BLUECONFIGS GITLAB_PIPELINES --write-commit-file=commit-mapping.env
    fi

    # Generate all modules
    echo "modules:
  tcl:
    naming_scheme: '\${PACKAGE}/\${VERSION}'
    whitelist:
      - '@:'
    " > ${SPACK_ROOT}/etc/spack/modules.yaml
    touch $SPACK_ROOT/spack_patched.flag
    echo "Done patching"
)

main || return 1
