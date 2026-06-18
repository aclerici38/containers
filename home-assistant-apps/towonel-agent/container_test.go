package main

import (
	"io"
	"net/http"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/home-operations/containers/testhelpers"
	"github.com/stretchr/testify/require"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"
)

const defaultImage = "ghcr.io/aclerici38/towonel-agent:rolling"

// TestBinaryRuns is the smoke test: the upstream glibc binary loads and runs on the
// Wolfi base (the whole reason we don't use an Alpine/musl base).
func TestBinaryRuns(t *testing.T) {
	image := testhelpers.GetTestImage(defaultImage)
	testhelpers.TestCommandSucceeds(t, image, nil, "/usr/local/bin/towonel-agent", "--help")
}

// TestImageContents confirms the image was assembled correctly: the agent, the
// options shim, and the two tools run.sh depends on — jq (parse options.json) and
// su-exec (drop privileges).
func TestImageContents(t *testing.T) {
	image := testhelpers.GetTestImage(defaultImage)
	for _, p := range []string{
		"/usr/local/bin/towonel-agent",
		"/run.sh",
		"/usr/bin/jq",
		"/usr/bin/su-exec",
	} {
		testhelpers.TestFileExists(t, image, p, nil)
	}
}

// TestEndToEnd exercises the real entrypoint end-to-end: it feeds a Home Assistant
// style /data/options.json and asserts the whole custom chain works — run.sh reads
// the options, jq translates them to env vars, su-exec drops to uid 10001, the agent
// loads and binds its health/metrics server, and the long-lived process is unprivileged.
//
// The shared helpers can't express this (TestHTTPEndpoint runs the entrypoint with no
// way to inject options.json, assert logs, or check the dropped uid), so it's built on
// testcontainers-go directly.
func TestEndToEnd(t *testing.T) {
	image := testhelpers.GetTestImage(defaultImage)
	ctx := t.Context()

	// Mirror how the Supervisor writes options: one field per config.yaml option.
	// `services` is schema type `str`, so it carries JSON as a string. The invite
	// token is intentionally bogus — the agent retries the hub connection forever, but
	// the health/metrics server binds regardless, which is exactly what we assert.
	const options = `{
  "invite_token": "tt_inv_2.aaaa.bbbb.cccc",
  "services": "[{\"hostname\":\"x.example.com\",\"origin\":\"localhost:1\"}]",
  "health_listen_addr": "0.0.0.0:9090",
  "log_level": "info"
}`
	optionsPath := filepath.Join(t.TempDir(), "options.json")
	require.NoError(t, os.WriteFile(optionsPath, []byte(options), 0o644))

	ctr, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: testcontainers.ContainerRequest{
			Image:        image,
			ExposedPorts: []string{"9090/tcp"},
			Files: []testcontainers.ContainerFile{{
				HostFilePath:      optionsPath,
				ContainerFilePath: "/data/options.json",
				FileMode:          0o644,
			}},
			// Start blocks until /healthz returns 200 — already proves the port
			// listens and the healthcheck path works through the full entrypoint.
			WaitingFor: wait.ForHTTP("/healthz").
				WithPort("9090/tcp").
				WithStartupTimeout(60 * time.Second),
		},
		Started: true,
	})
	testcontainers.CleanupContainer(t, ctr)
	require.NoError(t, err)

	// Explicit healthcheck + metrics path assertions.
	host, err := ctr.Host(ctx)
	require.NoError(t, err)
	port, err := ctr.MappedPort(ctx, "9090/tcp")
	require.NoError(t, err)
	base := "http://" + host + ":" + port.Port()

	client := &http.Client{Timeout: 10 * time.Second}
	for path, want := range map[string]int{"/healthz": 200, "/metrics": 200} {
		resp, err := client.Get(base + path)
		require.NoError(t, err, "GET %s", path)
		_ = resp.Body.Close()
		require.Equal(t, want, resp.StatusCode, "GET %s status", path)
	}

	// Log output: the agent announced the health server is listening.
	logs, err := ctr.Logs(ctx)
	require.NoError(t, err)
	defer logs.Close()
	out, err := io.ReadAll(logs)
	require.NoError(t, err)
	require.Contains(t, string(out), "health + metrics listening", "expected health server log line")

	// Privilege drop: PID 1 (the long-lived agent, after `exec su-exec`) is uid 10001,
	// not root. /proc/1/status reports the effective/real uid set.
	code, reader, err := ctr.Exec(ctx, []string{"cat", "/proc/1/status"})
	require.NoError(t, err)
	require.Equal(t, 0, code)
	status, err := io.ReadAll(reader)
	require.NoError(t, err)
	require.Regexp(t, `(?m)^Uid:\s+10001\s`, string(status), "agent (PID 1) should run as uid 10001, not root")
}
