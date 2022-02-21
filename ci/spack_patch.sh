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
    log "Patching Spack sources according to required branches..."
    # Generate all modules
    echo "modules:
  tcl:
    naming_scheme: '\${PACKAGE}/\${VERSION}'
    whitelist:
      - '@:'
    " > ${SPACK_ROOT}/etc/spack/modules.yaml
    touch $SPACK_ROOT/spack_patched.flag
)

main
