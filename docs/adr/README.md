<!-- SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com> -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# Architecture Decision Records

Decisions about this repository that will be questioned later, with the
reasoning that produced them. Records are immutable once merged; a
decision that changes gets a new record superseding the old one.

Decisions about the *format itself* — what a verdict means, how the score
is derived, why the format is Apache-2.0 — are scout's, in
[scout's ADRs](https://github.com/sebastienrousseau/scout/blob/main/docs/adr/README.md).
This directory records what is decided here.

| # | Decision | Status |
|---|---|---|
| [0001](0001-verifier-in-its-own-module.md) | The verifier is its own module; the rubric and the renderers stay in scout until a consumer needs them | Accepted |
