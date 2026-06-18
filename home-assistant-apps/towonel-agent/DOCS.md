# Towonel Agent

Runs the [towonel](https://codeberg.org/towonel/towonel) tunnel agent on your
Home Assistant OS instance — a self-hosted way to expose Home Assistant (and other
local services) through NAT / CGNAT / a dynamic IP **without opening any inbound
ports on your router**. A privilege-light alternative to Cloudflare Tunnel.

## How it works

The agent only ever makes **outbound** QUIC connections to the towonel relays and
reaches your local services as their "origin". There are no inbound ports, so the
add-on needs no `ports`, no `host_network`, and no router changes.

## Security posture

This add-on is built to be as unprivileged as Home Assistant allows:

- **Not s6 / not the HA base image.** Built on Wolfi (a glibc-based minimal base)
  with `init: false`, so the only PID 1 is a tiny `sh` script.
- **Drops root.** The script runs as root _only_ to read `/data/options.json`
  (which the Supervisor stores mode `0600`, root-only). It then `exec`s the agent
  as **uid/gid 10001** via `su-exec`. The long-lived agent process is unprivileged.
- **No writable state.** The agent is stateless — it generates an ephemeral
  identity in memory each start and persists nothing — so there is no data volume
  and the AppArmor profile denies filesystem writes.
- **No elevated access.** No `host_network`, no `hassio_api`/`homeassistant_api`,
  `hassio_role: default`, no `privileged`/`full_access`/`devices`/`map`.
- **AppArmor.** A bundled profile (`apparmor.txt`) restricts capabilities, network
  modes, and filesystem writes.

> The one unavoidable bit of root: a configurable HA add-on must read its own
> `options.json`, which is `0600` root-owned, so PID 1 starts as root for the few
> milliseconds it takes to read options and drop privileges. Fully non-root from
> PID 1 is not possible for any add-on that takes user configuration.

## Getting an invite token

Create one on your towonel hub (first run of the tenant):

```
towonel invite create
```

It looks like `tt_inv_2_...`. Paste it into **Invite token**. The token is reusable
on every agent start (the hub address is embedded in it), so no other connection
config is required.

## Options

| Option               | Required | Description                                                                                         |
| -------------------- | -------- | --------------------------------------------------------------------------------------------------- |
| `invite_token`       | yes      | The `tt_inv_2_...` token from your hub. Stored masked.                                              |
| `services`           | yes      | JSON array of HTTP services to expose (see below).                                                  |
| `tcp_services`       | no       | JSON array of raw TCP services.                                                                     |
| `udp_services`       | no       | JSON array of raw UDP services.                                                                     |
| `trusted_edges`      | no       | Advanced: restrict which edge node IDs the agent trusts. Blank = trust whatever the hub advertises. |
| `health_listen_addr` | no       | Health/metrics bind address. Default `127.0.0.1:9090` (container-internal).                         |
| `log_level`          | no       | `trace` / `debug` / `info` / `warn` / `error`. Default `info`.                                      |

### `services` — exposing Home Assistant

towonel only does **passthrough** TLS (the default — an older `terminate` mode was
removed): the edge reads the TLS SNI and forwards the raw, still-encrypted stream to
the origin, which **holds the certificate**. So the origin must be something that
terminates TLS — point it at your local TLS proxy (e.g. the **NGINX SSL proxy add-on**
serving your **certbot** certificate), reachable over the internal Supervisor network:

```json
[{ "hostname": "ha.example.com", "origin": "nginx_proxy:443" }]
```

Replace `nginx_proxy` with your proxy add-on's hostname. Do **not** point the origin
straight at `homeassistant:8123` — that's plain HTTP, and passthrough hands it raw TLS.

The agent prepends a **PROXY protocol v2** header so the proxy sees the real client IP;
your proxy must accept it (NGINX: `proxy_protocol` on the listener), or disable it
per-service with `"proxy_protocol": "none"`.

### `tcp_services` / `udp_services`

```json
[{ "name": "ssh", "origin": "homeassistant:22", "listen_port": 2222 }]
```

(`listen_port`s under 1024 require explicit hub configuration.)

## Notes

- Supported architectures are `amd64` and `aarch64` only — upstream publishes the
  agent for those two.
- The add-on does **not** build on your Home Assistant device. The image is built by
  this repo's CI and published to `ghcr.io/aclerici38/towonel-agent`; the Supervisor
  just pulls it (see `image:` in `config.yaml`).
- See the upstream docs: <https://towonel.dev/docs/agent/docker/>.
