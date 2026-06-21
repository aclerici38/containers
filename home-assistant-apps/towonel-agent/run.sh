#!/bin/sh
# Entrypoint for the towonel-agent app.
#
# Runs as root *only* to read /data/options.json (mode 0600, root-owned — the
# unprivileged user cannot read it), translates the options into the env vars the
# agent expects, then drops to uid/gid 10001 and replaces itself with the agent.
# After the `exec su-exec` line there is no root process left running.
set -eu

CONFIG=/data/options.json
AGENT=/usr/local/bin/towonel-agent
RUN_AS=10001:10001

if [ ! -r "$CONFIG" ]; then
    echo "[towonel-agent] FATAL: cannot read $CONFIG" >&2
    exit 1
fi

# Read a string option; prints nothing if null/absent.
opt() { jq -r --arg k "$1" '.[$k] // empty' "$CONFIG"; }

# --- Required ------------------------------------------------------------------
TOKEN="$(opt invite_token)"
if [ -z "$TOKEN" ]; then
    echo "[towonel-agent] FATAL: 'invite_token' is empty. Set it in the app" >&2
    echo "[towonel-agent]        configuration (get one with: towonel invite create)." >&2
    exit 1
fi
export TOWONEL_INVITE_TOKEN="$TOKEN"

SERVICES="$(opt services)"
if [ -z "$SERVICES" ]; then
    echo "[towonel-agent] FATAL: 'services' is empty." >&2
    exit 1
fi
export TOWONEL_AGENT_SERVICES="$SERVICES"

# --- Optional ------------------------------------------------------------------
TCP="$(opt tcp_services)";     [ -n "$TCP" ]   && export TOWONEL_AGENT_TCP_SERVICES="$TCP"
UDP="$(opt udp_services)";     [ -n "$UDP" ]   && export TOWONEL_AGENT_UDP_SERVICES="$UDP"
EDGES="$(opt trusted_edges)";  [ -n "$EDGES" ] && export TOWONEL_AGENT_TRUSTED_EDGES="$EDGES"

HEALTH="$(opt health_listen_addr)"
[ -n "$HEALTH" ] && export TOWONEL_AGENT_HEALTH_LISTEN_ADDR="$HEALTH"

export RUST_LOG="$(jq -r '.log_level // "info"' "$CONFIG")"

# --- Extra env (escape hatch) --------------------------------------------------
# Each entry of the `extra_env` array is a {name, value} object; flatten to a
# "name=value" line and export it verbatim. Applied last, so it can override any
# mapping above. Entries with an empty name are skipped. The heredoc
# keeps the loop in this shell so the exports survive to the exec below.
while IFS='=' read -r name value; do
    [ -z "$name" ] && continue
    export "$name=$value"
done <<EOF
$(jq -r '.extra_env[]? | select(.name != null and .name != "") | "\(.name)=\(.value // "")"' "$CONFIG")
EOF

echo "[towonel-agent] starting agent as ${RUN_AS} (dropping root)"
# Final, long-lived process runs unprivileged. exec keeps it as PID 1 so signals
# (SIGTERM on app stop) reach the agent directly. su-exec is the Wolfi/Alpine
# equivalent of gosu and takes the same uid:gid spec.
exec su-exec "$RUN_AS" "$AGENT"
