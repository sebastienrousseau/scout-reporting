<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

<p align="center">
  <img src="https://raw.githubusercontent.com/sebastienrousseau/scout/main/.github/logo.svg" alt="scout-reporting logo" width="128" />
</p>

<h1 align="center">scout-reporting</h1>

<p align="center">
  The attestation a scout run makes about a Model Context Protocol server, and the verifier that checks one offline — licensed so a gateway, registry or CI system can embed it.
</p>

<p align="center">
  <a href="https://github.com/sebastienrousseau/scout-reporting/actions"><img src="https://img.shields.io/github/actions/workflow/status/sebastienrousseau/scout-reporting/ci.yml?style=for-the-badge&logo=github" alt="Build Status" /></a>
  <a href="https://pkg.go.dev/github.com/sebastienrousseau/scout-reporting"><img src="https://img.shields.io/badge/go.dev-reference-007d9c?style=for-the-badge&logo=go&logoColor=white" alt="Go Reference" /></a>
  <a href="https://pkg.go.dev/github.com/sebastienrousseau/scout-reporting/attestation"><img src="https://img.shields.io/badge/docs-attestation-brightgreen?style=for-the-badge&logo=go&logoColor=white" alt="Documentation" /></a>
  <a href="https://scorecard.dev/viewer/?uri=github.com/sebastienrousseau/scout-reporting"><img src="https://img.shields.io/ossf-scorecard/github.com/sebastienrousseau/scout-reporting?style=for-the-badge&label=OpenSSF%20Scorecard&logo=openssf" alt="OpenSSF Scorecard" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache--2.0-blue?style=for-the-badge" alt="License: Apache-2.0" /></a>
  <a href="#requirements"><img src="https://img.shields.io/github/go-mod/go-version/sebastienrousseau/scout-reporting?style=for-the-badge&logo=go&logoColor=white&label=Go" alt="Minimum Go version" /></a>
</p>

---

## Contents

**Getting started**

- [Install](#install) — `go get`, or the schema alone
- [Requirements](#requirements) — the Go floor, and nothing else
- [Quick Start](#quick-start) — verify a statement in twelve lines

**The scout-reporting ecosystem**

- [The scout-reporting ecosystem](#the-scout-reporting-ecosystem) — `scout`, `scout-reporting`, `scout-action`, `scout-mcp`, `scout-lsp`, `scout-census` at a glance

**Library reference**

- [Capabilities at a glance](#capabilities-at-a-glance) — the current surface by theme
- [Ecosystem comparison](#ecosystem-comparison) — what this is beside, and is not
- [Benchmarks](#benchmarks) — what an admission decision costs
- [Features](#features) — what a statement carries and what the verifier checks
- [Configuration](#configuration) — there is none
- [Examples](#examples) — runnable example index

**Operational**

- [When not to use scout-reporting](#when-not-to-use-scout-reporting) — limitations
- [Development](#development) — make targets, what is generated, CI
- [Security](#security) — what `Validate` guarantees and what it does not
- [Documentation](#documentation) — all reference docs
- [Stability guarantees](#stability-guarantees) — the breaking axis is what `Validate` accepts
- [License](#license)

---

## Install

### As a Go library

```sh
go get github.com/sebastienrousseau/scout-reporting@v0.0.6
```

The module has no dependencies: adding it adds one line to `go.sum`.

### The schema alone

A consumer that validates by JSON Schema rather than by importing Go takes
[`spec/attestation/mcp-evaluation-v1.schema.json`](spec/attestation/mcp-evaluation-v1.schema.json)
(JSON Schema 2020-12). It is generated from the Go types and CI fails when
the two disagree, so both routes accept the same statements.

---

## Requirements

| Requirement | Floor | Enforced by |
|---|---|---|
| Go | the `go` directive in [`go.mod`](go.mod) | CI tests on that version and on latest stable, on Linux, macOS and Windows |
| Dependencies | none | `go.mod` has no `require` directive, and a pull request that adds one is declined |
| Network | none | the verifier reads bytes it is given and nothing else |

The floor is raised only when a release needs a language feature, on a
patch release like everything else pre-1.0, and the changelog says so.

---

## Quick Start

```go
package main

import (
    "fmt"
    "os"

    "github.com/sebastienrousseau/scout-reporting/attestation"
)

func main() {
    b, _ := os.ReadFile("statement.json")
    st, err := attestation.Parse(b)
    if err != nil {
        panic(err)
    }
    if err := st.Validate(); err != nil {
        panic(err) // the digest, the subject, the predicate type or a required field is wrong
    }
    if !st.Covers("http", "https://mcp.example.com/mcp") {
        panic("about a different server")
    }
    fmt.Println(st.Predicate.Score.Total, st.Predicate.Score.Grade)
}
```

`Parse` reads the in-toto envelope. `Validate` recomputes the subject digest
from the predicate's target and refuses a statement whose displayed subject
was rewritten, a score without its rubric version, or a predicate of another
type. `Covers` asks whether the statement is about the target you are about
to trust. What you do with the score is your policy; the statement carries
the verdict of every check that ran, so a gate can be as specific as
"no `fail` in `auth.*`".

A statement is produced by [scout](https://github.com/sebastienrousseau/scout):
`scout check … --output attestation`, or `scout attest report.json`. Signing
it, and checking the signature, is the envelope's job — see
[docs/verify.md](docs/verify.md).

---

## The scout-reporting ecosystem

One engine, three surfaces, five satellites. This repository is the
licence boundary: the part of scout other people's software imports.

| Component | Purpose | Use case |
| :--- | :--- | :--- |
| [`scout`](https://github.com/sebastienrousseau/scout) | The engine, every check, and the CLI, TUI and web surfaces (GPL-3.0-only) | Evaluate a server and write the statement |
| **`scout-reporting`** | The attestation format, its schema and the offline verifier (Apache-2.0) | Gate on a statement in a gateway, registry or pipeline |
| [`scout-action`](https://github.com/sebastienrousseau/scout-action) | The GitHub Action and GitLab template wrapping the published image by digest (Apache-2.0) | Run scout in CI without installing it |
| `scout-mcp` | scout's diagnostics as MCP tools (planned) | Evaluate a server from inside an editor |
| `scout-lsp` | A language server over MCP artefacts (planned) | Hover a check id for its remediation |
| `scout-census` | The published reliability census (planned) | Reproduce the numbers |

The family manifest lives in scout at
[`docs/ecosystem.md`](https://github.com/sebastienrousseau/scout/blob/main/docs/ecosystem.md);
`make family` checks this repository's row against it. Every lockstep
repository carries scout's version, and this one tags first because scout
imports it.

---

## Capabilities at a glance

| Area | Capability | Status |
| :--- | :--- | :--- |
| Read | `Parse` an in-toto v1 Statement carrying the `mcp-evaluation/v1` predicate | Stable |
| Integrity | `Validate` recomputes the subject digest from the target descriptor and checks every required field | Stable |
| Scope | `Covers(transport, endpoint)` says whether a statement is about a given target | Stable |
| Lookup | `VerdictFor(id)` returns one check's outcome, or `ErrNoSuchCheck` | Stable |
| Drift | `Compare(before, after)` names what got worse, what got better, what appeared and what disappeared | Stable |
| Produce | `SubjectFor(target)` digests a target exactly as `Validate` recomputes it | Stable |
| Schema | `spec.AttestationSchema`, the same bytes as the committed file | Stable |
| Gateway | `integrations/agentgateway-extmcp`, an `ExtMcp` processor for agentgateway built on this package | Example |
| Signatures | verifying who wrote the bytes | Out of scope — the envelope's job |

---

## Ecosystem comparison

There is no other MCP evaluation attestation to compare against: the
official conformance suite reports pass and fail to a terminal and writes
no portable claim, and the registries display what a server says about
itself. What this format sits beside is the supply-chain machinery it
reuses, and the comparison worth making is with those envelopes.

| Project | Portable claim | Verifies offline | About an MCP server |
| :--- | :---: | :---: | :---: |
| **scout-reporting** | yes | yes | yes |
| SLSA provenance | yes | yes | no — about a build |
| CycloneDX / SPDX SBOM | yes | yes | no — about components |
| MCP conformance suite | no | — | yes |

The format is an in-toto Statement so that it verifies with the same tools
and sits in the same policy as the first two rows.

---

## Benchmarks

An admission decision — parse and validate a statement, digest included —
costs microseconds and allocates once per verdict. Measured with
`go test -bench Validate -benchmem` in [`attestation`](attestation/);
numbers and machine in [`docs/BENCHMARKS.md`](docs/BENCHMARKS.md).

| Scenario | Result | Environment |
| :--- | ---: | :--- |
| Parse + Validate, 2-verdict fixture (1.3 KB) | 3.8 µs, 17 allocations | Apple A18 Pro, Go 1.26.8, 2026-09-23 |
| Parse + Validate, 120-verdict statement (28 KB) | 66 µs, 390 allocations | same |

---

## Features

**What a statement carries.** One subject — the evaluated server, digested
as a target descriptor and marked as such — and a predicate with the
target, what it was judged against (MCP revision, rubric version, check
inventory), the instrument, when it ran, the verdict for every check that
ran with its evidence references, the counts, the score, why the run
stopped early if it did, and the plan that produced it with secret values
removed. [docs/format.md](docs/format.md) describes each field and why it
is there.

**What the verifier checks.** The envelope type and predicate type; exactly
one subject, named as the target and digested as the descriptor; every
required field; a rubric version wherever there is a score; a verdict
status from the closed set. It does not check signatures, and it never
follows a reference.

**What the verifier does not do.** Fetch, sign, score or judge. Producing
a statement is scout's job; deciding what a score means is yours.

---

## Configuration

None. The verifier is a pure function of the bytes it is given, which is
the property a gateway wants from something it trusts: nothing to
misconfigure, nothing that changes between two machines.

---

## Examples

| Example | Shows |
|---|---|
| [`examples/verify`](examples/verify/main.go) | Read a statement, validate it, print the score and every failing check — the smallest admission hook |
| [`attestation/example_test.go`](attestation/example_test.go) | The package's own runnable example, checked by `go test` |
| [`integrations/agentgateway-extmcp`](integrations/agentgateway-extmcp/README.md) | A complete consumer: an [agentgateway](https://github.com/agentgateway/agentgateway) `mcpGuardrails` processor that denies calls to a backend whose attestation is missing, invalid, below a score floor or failing in a named category. Its own module, so the root stays dependency-free |

```sh
go run ./examples/verify attestation/testdata/statement.json
```

---

## When not to use scout-reporting

- **To produce a statement.** Only scout writes one; this package reads
  them. `SubjectFor` is exported so a producer digests a target the way
  a verifier recomputes it, not so a second producer exists.
- **As proof of who wrote the bytes.** `Validate` checks integrity and
  structure. A statement that validates could still have been written
  by anyone; sign it and verify the signature with the envelope of your
  choice.
- **To recompute a score.** The rubric is published in scout's `spec/`,
  generated from the scorer. This package carries a score and its rubric
  version and does not re-derive it.
- **For anything but MCP evaluations.** The predicate type is fixed; a
  statement of another type is refused rather than guessed at.

---

## Development

```bash
make            # format, vet, lint, headers, schema, example, tests
make test-race  # race detector, randomised order
make spec       # regenerate the schema after a type change
make family     # this repository's row in scout's family manifest
make lockstep   # the version is scout's, or the next one
```

Every gate CI runs has a local form; [DEVELOPMENT.md](DEVELOPMENT.md) maps
them. `spec/attestation/` is generated and never edited by hand.

---

## Security

`Validate` recomputes the subject digest and refuses a rewritten subject, a
second subject, a score without its rubric, or a predicate of another
type; each refusal is a test. The package imports only the standard
library, opens no file and no connection, and CI runs `govulncheck` on
every push. What it does not check is a signature: that is the envelope
around the statement, and a consumer must verify both.

Report vulnerabilities according to [`SECURITY.md`](SECURITY.md).

---

## Documentation

The four entry points, identical across every repo in the family:

- **[User Manual](https://scoutmcp.io/manual/)** — scout's rendered manual, including how a statement is produced and signed
- **[API reference](https://pkg.go.dev/github.com/sebastienrousseau/scout-reporting)** — this module's packages
- **[Developer docs](DEVELOPMENT.md)** — toolchain, task map, reproducing every CI gate locally
- **[Ecosystem map](https://github.com/sebastienrousseau/scout/blob/main/docs/ecosystem.md)** — the family, the published artefacts, the lockstep version rule

| Document | Covers |
|---|---|
| [`docs/format.md`](docs/format.md) | Every field of a statement, and why it is there |
| [`docs/verify.md`](docs/verify.md) | Verifying one: in Go, by schema, and the signature around it |
| [`docs/BENCHMARKS.md`](docs/BENCHMARKS.md) | What an admission decision costs |
| [`docs/adr/`](docs/adr/README.md) | Decision records for this repository |
| [`spec/`](spec/README.md) | The published schema, and where the rubric is |
| [`SECURITY.md`](SECURITY.md) | Disclosure policy, supported versions, what is guaranteed |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Signed-commit and DCO policy, what a format change needs |
| [`CHANGELOG.md`](CHANGELOG.md) | Per-release notes, and the lockstep version rule |
| [`SUPPORT.md`](SUPPORT.md) | Where to ask, and what to expect |

---

## Stability guarantees

scout-reporting is pre-1.0, carries scout's version, and follows SemVer
with the patch digit moving for everything until 1.0.

**The breaking axis is what `Validate` accepts.** A statement this version
rejects and the previous one accepted — or the reverse — is a breaking
change whether or not a signature moved, because a gateway on either side
of it makes a different admission. Specifically, these are breaking:

- A required field added to, or removed from, the predicate
- A change to how the subject digest is computed
- A change to the predicate type or the statement type
- A verdict status added to or removed from the closed set

Added optional fields, new helpers, and stricter checks that only reject
statements scout never wrote are **not** breaking. Every breaking change
lands with a tracking issue open for at least a week and a changelog entry
that names it.

**Deprecation window.** A deprecated function keeps working for at least
one release after the release that announces it.

---

## License

Licensed under the **[Apache License 2.0](LICENSE)**.

The engine that produces these statements, [scout](https://github.com/sebastienrousseau/scout),
is GPL-3.0-only. This repository is Apache-2.0 so that the format can be
implemented and the verifier embedded without taking on the engine's
licence — scout's [ADR 0011](https://github.com/sebastienrousseau/scout/blob/main/docs/adr/0011-attestation-format-is-apache.md)
records why.

<p align="right"><a href="#contents">Back to Top</a></p>
