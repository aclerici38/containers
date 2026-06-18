# syntax=docker/dockerfile:1
ARG VERSION
FROM codeberg.org/towonel/towonel-agent:${VERSION} AS upstream

FROM cgr.dev/chainguard/wolfi-base:latest

# jq      -> parse /data/options.json (no bashio, no HA base image needed)
# su-exec -> drop from root to an unprivileged uid before exec'ing the agent
#            (~10 KB; the Wolfi/Alpine equivalent of gosu)
# ca-certificates-bundle -> trust roots for the agent's outbound TLS/QUIC
# /data is the app data dir the Supervisor bind-mounts options.json into; create
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

ENTRYPOINT ["/run.sh"]
