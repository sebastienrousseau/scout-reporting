<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Changelog

All notable changes to scout-reporting are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
versions are [Semantic Versioning](https://semver.org/) shaped.

**This repository carries scout's version.** It is in lockstep with
[scout](https://github.com/sebastienrousseau/scout): every release here is
a scout release, whatever changed in this tree, and a release here with
nothing in it is the version rule working. Because scout imports this
module, this repository tags first.

## [Unreleased]

## [0.0.4] — 2026-09-23

### Added

- **The attestation verifier, in its own module.** The package
  `github.com/sebastienrousseau/scout-reporting/attestation` is the
  in-toto statement scout writes about one MCP server and everything
  needed to read and check one offline: `Parse`, `Validate`, `Covers`,
  `VerdictFor`, `Compare` for drift between two statements, and
  `SubjectFor` so a producer digests a target exactly as a verifier
  recomputes it. Apache-2.0, standard library only, no dependencies.

  Extracted from `github.com/sebastienrousseau/scout/attestation`
  unchanged, so a statement either module accepts the other accepts. It
  moved because importing a package from scout's module pulls scout's
  whole dependency graph into a consumer's `go.sum`, terminal UI included,
  which is not what a gateway signs up for when it adds a verifier.
  scout's own package now forwards here and is deprecated.

- **The predicate's JSON Schema**, generated from the types by
  `scripts/specgen` and gated in CI, at
  `spec/attestation/mcp-evaluation-v1.schema.json`. The `spec` package
  embeds it for a consumer that validates by schema rather than by
  importing the verifier.

- **`examples/verify`**, the smallest consumer: read a statement, check
  it, print the score and every failing check.

- **`integrations/agentgateway-extmcp`**, a complete consumer: an
  [agentgateway](https://github.com/agentgateway/agentgateway)
  `mcpGuardrails` processor over gRPC that gates MCP backends on their
  attestations — denied, with a reason naming the backend, when the
  statement is missing, invalid, about another endpoint, below a score
  floor or failing a check in a named category. Its own Go module, built
  from this checkout, so the root module keeps no dependency; statements
  are loaded at startup and on reload, over https with a size cap or from
  a file, never per request. Signature verification is out of scope.

### Not here

- **The scoring rubric** stays in scout, at `spec/rubric/`, because it
  is generated from the scorer and the scorer is the one thing it must
  never disagree with. It moves when the scorer reads it as data.
- **The report renderers**, until a consumer outside scout needs them.

[Unreleased]: https://github.com/sebastienrousseau/scout-reporting/compare/v0.0.4...HEAD
[0.0.4]: https://github.com/sebastienrousseau/scout-reporting/releases/tag/v0.0.4
