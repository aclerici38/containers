# Changelog

## 0.1.0

- Initial draft of the towonel-agent add-on.
- Runs the long-lived agent unprivileged (uid/gid 10001) via `su-exec`.
- Wolfi (glibc) base — Alpine-small but ABI-compatible with the upstream binary.
- No s6 (`init: false`, plain `sh` entrypoint).
- No host network, no Supervisor/HA API, no privileged flags, no writable volume.
- Bundled restrictive AppArmor profile.
