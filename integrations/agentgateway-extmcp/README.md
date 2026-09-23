<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# agentgateway-extmcp

An [agentgateway](https://github.com/agentgateway/agentgateway) `mcpGuardrails`
processor that gates MCP backends on scout attestations.

agentgateway can hand every MCP method to an external policy server over
gRPC before forwarding it (the `ExtMcp` service in `proto/ext_mcp.proto`).
This processor answers those calls from a table of scout attestations —
one in-toto statement per backend — verified offline at startup against a
policy. A backend whose statement is missing, invalid, about a different
endpoint, below the score floor, or failing a check in a disqualifying
category is denied with a reason that names it; everything else passes.

It is an example integration, small on purpose: a few hundred lines around
the [`attestation`](../../attestation) package, which is the same code any
Go consumer embeds to verify a statement. Nothing here re-implements
verification.

## What it decides

For each backend named in `McpRequest.service_names`, in order:

| Condition | Answer |
|---|---|
| Method is in `passthroughMethods` | `Pass`, no table lookup |
| Backend not in `targets` | deny `no attestation configured` (or pass when `requireAttestation: false`) |
| Statement unreadable, fails `Parse`/`Validate`, or does not `Cover` the configured endpoint | deny `attestation unusable: …` (or pass when `requireAttestation: false`) |
| `minScore > 0` and the statement has no score, or a lower one | deny `score N is below the minimum M` |
| Any verdict with `status: fail` whose phase is in `denyFailIn` | deny `failing checks in category X (ids)` |
| Otherwise | `Pass`; scores ride along in the result's `metadata` under `scout.<target>` |

Denials are `AuthorizationError` with code `PERMISSION_DENIED`, which the
gateway turns into JSON-RPC error `-32001` carrying the reason.
`CheckResponse` always passes: the attestation is about the server, not
about one response.

A processor with no configuration loaded answers with gRPC `UNAVAILABLE`
rather than a decision, so the gateway's `failureMode` decides what
happens, not this code.

## Running it

```sh
go run ./cmd/agentgateway-extmcp -config example/config.json -listen 127.0.0.1:4400
```

Flags: `-config` (required), `-listen` (default `127.0.0.1:4400`; use
`0.0.0.0:…` in a container), `-reload-interval` (default off),
`-max-bytes` (default 1 MiB per statement), `-fetch-timeout` (default
10s), `-log-level`. Diagnostics are JSON lines on stderr.

Statements are read once at startup. `SIGHUP` re-reads the configuration
and every statement; `-reload-interval` does the same on a timer. A
reload whose configuration does not parse is logged and the previous
table stays in service.

### Configuration

[`example/config.json`](example/config.json):

```json
{
  "targets": {
    "github": {
      "attestation": "https://attestations.example.com/github-mcp.intoto.json",
      "endpoint": "https://api.githubcopilot.com/mcp/",
      "transport": "http"
    }
  },
  "policy": {
    "minScore": 70,
    "denyFailIn": ["auth", "protocol"],
    "requireAttestation": true
  },
  "passthroughMethods": ["initialize", "ping"]
}
```

- `targets` keys are agentgateway backend names, exactly as they appear
  in the gateway's `mcp.targets[].name`.
- `attestation` is a file path or an `https://` URL. `http://` is
  refused; a statement that could be swapped in transit is not evidence.
- `endpoint` and `transport` describe the server scout evaluated. They
  are checked through the statement's subject digest (`Covers`), not by
  string comparison, so a statement about one server cannot be pointed
  at another.
- `denyFailIn` names verdict phases, such as `auth`, `protocol`,
  `tools`; see scout's check inventory for the list.

### Pointing agentgateway at it

[`example/agentgateway.yaml`](example/agentgateway.yaml) is a complete
local configuration. The relevant part:

```yaml
mcp:
  policies:
    mcpGuardrails:
      processors:
        - kind: remote
          host: 127.0.0.1:4400
          failureMode: failClosed
          methods:
            tools/call: request
            tools/list: request
```

`methods` is the gateway's allowlist; methods it does not match never
reach the processor. `failClosed` is the setting that makes the gate a
gate.

## Out of scope

- **Signature verification.** The processor checks that a statement is
  well-formed, self-consistent and about the configured server; it does
  not check who signed it. Verify a DSSE envelope with your existing
  tooling (cosign, in-toto) before placing the statement where this
  processor reads it, or serve it from a location only your pipeline can
  write. The `attestation` package is the payload half of that pipeline
  on purpose.
- **TLS between the gateway and the processor.** The gRPC listener is
  plaintext; put it on loopback or a private network, or terminate TLS
  in front of it and configure `backendTLS` on the processor entry.
- **Response inspection and request mutation.** Both are in the wire
  contract and neither is used.

## Development

```sh
make            # vet, lint, test
make test-race
make generate   # regenerate gen/extmcp from proto/ext_mcp.proto
```

The module is nested: it has its own `go.mod` so the root module stays
free of dependencies. Until scout-reporting `v0.0.4` is tagged it uses
a `replace` directive pointing at the enclosing repository; a consumer
outside this tree should require `v0.0.4` instead. Lint uses the
repository's `.golangci.yml`. Generated bindings are committed; see
[`proto/README.md`](proto/README.md) for their provenance.
