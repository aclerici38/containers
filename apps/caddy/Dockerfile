FROM caddy:${VERSION}-builder AS builder
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare@${CLOUDFLARE_VERSION} \
    --with github.com/mholt/caddy-l4@${L4_VERSION}

FROM caddy:${VERSION}-alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
