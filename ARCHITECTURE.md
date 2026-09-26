<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Architecture

scout-reporting is the Apache-2.0 half of
[scout](https://github.com/sebastienrousseau/scout): the attestation
format scout writes, the offline verifier any consumer can embed, the
format's JSON Schema, and an agentgateway processor built on the
verifier. It runs no diagnostics; scout does that.

## The one decision

**The format is Apache-2.0; the engine stays GPL.** A gateway, registry
or CI system that wants to act on scout's evidence must be able to embed
the code that reads it without taking on the engine's licence. So the
statement types, the verifier and the schema live here, in a module with
no third-party dependencies, and scout imports them back. Importing this
module brings no other module into a consumer's `go.sum`.

## Modules and packages

| Path | Module | Role |
| :--- | :--- | :--- |
| `attestation` | root | Statement types; `Parse`, `Validate`, `Covers`, `VerdictFor`, `Compare`, `Marshal`, `SubjectFor` |
| `spec` | root | The predicate's JSON Schema as embedded bytes, for consumers that validate against the schema |
| `spec/attestation/` | root | The same schema as a published file |
| `examples/verify` | root | A complete offline verification, as a runnable program |
| `scripts/specgen` | root | Generates the schema from the `attestation` types; CI fails on drift |
| `integrations/agentgateway-extmcp` | nested | The agentgateway `mcpGuardrails` processor, with gRPC |

The root module requires nothing. The processor is a separate module so
its gRPC dependency never reaches a verifier consumer.

## What a statement is

An [in-toto](https://in-toto.io) Statement whose predicate type is
`https://scoutmcp.io/attestation/mcp-evaluation/v1`. Its subject is a
digest of the endpoint and transport scout evaluated. Its predicate
carries the instrument (scout's version), the time, the protocol
revision, every verdict with its phase and status, the score with its
rubric version, and the recorded run plan. [docs/format.md](docs/format.md)
is the full description.

## How verification works

```text
bytes ──► Parse ──► Covers(transport, endpoint) ──► your policy
           │          │
           │          └ recomputes the subject digest from the endpoint and
           │            transport; never compares strings, so a statement
           │            about one server cannot be pointed at another
           └ decodes, then Validate: the in-toto and predicate types, one
             subject named for the endpoint the predicate describes and
             whose digest covers it, counts that match the verdicts, and a
             rubric version on any score
```

Everything is offline and deterministic. Signature verification is not
here: verify the DSSE envelope with the tooling you already trust
(cosign, in-toto) and hand the payload to `Parse`.
[docs/verify.md](docs/verify.md) walks through it.

## The agentgateway processor

`integrations/agentgateway-extmcp` answers agentgateway's `ExtMcp` gRPC
calls from a table of statements, one per backend, loaded at startup and
on SIGHUP or an interval, never per request:

```text
agentgateway ──ExtMcp CheckRequest──► processor
                                       │ for each backend in service_names:
                                       │   statement present, valid, covering
                                       │   the configured endpoint, score ≥ floor,
                                       │   no failing check in a denied phase?
                                       ◄── Pass (scores in metadata)
                                           or PERMISSION_DENIED naming the backend
```

A processor with no configuration loaded answers `UNAVAILABLE`, so the
gateway's `failureMode` decides, not this code. Inside a checkout,
`go.work` builds it against the verifier at the same commit; installed,
it requires the tagged release.

## Lockstep

This repository carries scout's version, and tags first on each release,
because scout imports it. `scripts/lockstep.sh` allows it to be exactly
one patch ahead of scout's latest release.
