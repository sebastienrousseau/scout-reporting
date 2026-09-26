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

### Added

- **The agentgateway processor ships as a container and completes in the
  shell.** `integrations/agentgateway-extmcp/Dockerfile` builds it from its
  directory alone, as `go install` sees the module, onto a distroless
  nonroot base; both bases are pinned by digest, and the image listens on
  all interfaces and reads `/etc/extmcp/config.json`. CI builds the image
  and waits for the processor to listen in it. `-completion
  bash|zsh|fish` prints a completion script generated from the flag set,
  offering file names for `-config` and the four levels for `-log-level`.

### Changed

- **A manual, an architecture page and a template README.** The docs
  are built with MkDocs from scout's hash-locked requirements, strictly on
  every pull request, and deployed to GitHub Pages from main.
  `ARCHITECTURE.md` explains why the format is a separate Apache-2.0
  module, what a statement is, how verification works and where the
  agentgateway processor fits. The README follows the portfolio template,
  which `scripts/readme-check.sh` now enforces in CI.

### Fixed

- **The agentgateway processor installs with `go install`.** 0.0.6
  tagged its nested module and documented the install, but the module's
  `go.mod` carried a `replace` directive, which `go install` refuses, so
  the documented command failed. The directive is gone: the module
  requires scout-reporting v0.0.6, and a repository `go.work` keeps
  builds from a checkout on the verifier at the same commit. CI and
  `make integrations` build it the way `go install` does and refuse a
  `replace`. Found by the v0.0.6 release audit.

## [0.0.6] — 2026-09-25

In lockstep with scout 0.0.6. Nothing in the `attestation` package or
the spec changed; the release is the agentgateway processor's.

### Added

- **The agentgateway processor installs with `go install`.** Its nested
  module is tagged `integrations/agentgateway-extmcp/v0.0.6` alongside
  this release, so
  `go install github.com/sebastienrousseau/scout-reporting/integrations/agentgateway-extmcp/cmd/agentgateway-extmcp@v0.0.6`
  resolves without a checkout. Earlier releases tagged only the root
  module. *Correction:* the install fails at v0.0.6, because the
  module's `go.mod` still carried a `replace` directive; it works from
  0.0.7.

### Fixed

- **The agentgateway processor no longer logs after it has stopped.**
  `run` returned without waiting for its reload goroutine, so a reload
  could still write a log line after the caller believed the process had
  stopped. The goroutine is now joined before `run` returns. The race
  detector found it in CI under the grpc 1.83 update's timing.
- **The agentgateway example no longer gates `tools/list`.** One
  listing spans every target, so a single unattested backend denied the
  whole listing and the agent saw no tools, attested ones included.
  Calls to an unattested backend are still denied. Found by running the
  example end to end against agentgateway v1.5.0.

### Changed

- **The processor README says where `mcpGuardrails` goes.**
  agentgateway rejects it on an individual target; it belongs under
  `mcp.policies` or a route, and per-backend gating comes from
  `service_names`. The README also notes that `denyFailIn: [protocol]`
  denies a server that fails `protocol.origin`, whatever its score.

## [0.0.5] — 2026-09-24

In lockstep with scout 0.0.5. Nothing in the `attestation` package or the
schema changed; the processor gains one fix, and the rest is how the
repository checks itself.

### Fixed

- **A SIGHUP just after the agentgateway processor starts no longer
  kills it.** The handler was installed by a goroutine after the process
  announced it was listening, so a hangup in that window took the default
  action; an operator reloading straight after a start stopped the gate.
  The handler now goes in before anything is announced. CI found it, as a
  test killed by its own signal under one shuffle order on a slower
  runner.

- **The coverage gate no longer dies on a package with no statements.**
  `spec` only embeds a file, so `go test` reports "[no statements]", the
  gate's search for a percentage found nothing, and the job ended there.
  Such packages, and the example program, which `make example-check`
  runs instead, are skipped rather than failed.
- **Text files check out with LF on every platform.** The fixture and the
  published schema are compared byte for byte by their tests, so a CRLF
  checkout on Windows read both as stale.
- **`scripts/lockstep.sh` and `scripts/family.sh` fetch to a file before
  parsing.** A download piped into an interpreter is what OpenSSF
  Scorecard reads as download-then-run, whatever the bytes are.

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

[Unreleased]: https://github.com/sebastienrousseau/scout-reporting/compare/v0.0.6...HEAD
[0.0.6]: https://github.com/sebastienrousseau/scout-reporting/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/sebastienrousseau/scout-reporting/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/sebastienrousseau/scout-reporting/releases/tag/v0.0.4
