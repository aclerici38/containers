# syntax=docker/dockerfile:1

# 1) Grab the prebuilt, statically-linked agent binary from the upstream distroless
#    image. It is multi-arch (amd64/arm64), so the per-platform CI build copies the
#    matching binary. Pinned by tag@digest (Renovate bumps it); the tag is kept in
#    lockstep with VERSION in docker-bake.hcl, which is the published image tag.
FROM codeberg.org/towonel/towonel-agent:0.2.2@sha256:9a749db23ce3cf4c208fe3d275b5857d57b15744a291efca751dc0c3e6f604fc AS upstream

# 2) Minimal glibc runtime. Wolfi is Alpine-small but glibc-based, matching the
#    upstream distroless/cc-debian12 ABI — the agent binary is dynamically linked
#    against glibc and would NOT load on Alpine/musl. Pinned by digest like the
#    base images in apps/.
FROM cgr.dev/chainguard/wolfi-base:latest@sha256:34977aa13765da89f60fee8fe5230e2bb1c55192df08e383c58221ee0d1277fb

# jq      -> parse /data/options.json (no bashio, no HA base image needed)
# su-exec -> drop from root to an unprivileged uid before exec'ing the agent
#            (~10 KB; the Wolfi/Alpine equivalent of gosu)
# ca-certificates-bundle -> trust roots for the agent's outbound TLS/QUIC
# /data is the add-on data dir the Supervisor bind-mounts options.json into; create
# the mount point so it exists even before the mount (and for tests that inject it).
RUN apk add --no-cache jq su-exec ca-certificates-bundle \
    && addgroup -g 10001 -S towonel \
    && adduser  -u 10001 -G towonel -S -D -H -s /sbin/nologin towonel \
    && mkdir -p /data \
    && su-exec nobody true   # sanity-check su-exec works in this image

# The agent binary lives at the same path as upstream. Set perms via --chmod so the
# binary isn't duplicated into a second layer by a follow-up `RUN chmod`.
COPY --from=upstream --chmod=0555 /usr/local/bin/towonel-agent /usr/local/bin/towonel-agent
COPY --chmod=0555 run.sh /run.sh

# init: false in config.yaml means this is PID 1. run.sh reads options as root,
# then exec's the agent as uid/gid 10001 (no s6, no lingering root process).
ENTRYPOINT ["/run.sh"]
