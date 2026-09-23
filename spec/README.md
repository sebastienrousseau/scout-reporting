<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# The published schema

[`attestation/mcp-evaluation-v1.schema.json`](attestation/mcp-evaluation-v1.schema.json)
is JSON Schema 2020-12 for an in-toto Statement carrying the
`https://scoutmcp.io/attestation/mcp-evaluation/v1` predicate.

It is generated from the Go types in [`../attestation`](../attestation)
by `make spec`, and CI fails when it drifts. Do not edit it by hand. The
`spec` Go package embeds the same bytes, so a Go program validating by
schema and one importing the verifier agree.

The scoring rubric — weights, deductions, grade bands — is not here. It is
generated from scout's scorer and published in scout's
[`spec/rubric/`](https://github.com/sebastienrousseau/scout/tree/main/spec/rubric),
because the scorer is the one thing it must never disagree with
([ADR 0001](../docs/adr/0001-verifier-in-its-own-module.md)).

[docs/format.md](../docs/format.md) describes every field.
