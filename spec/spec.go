// SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
// SPDX-License-Identifier: Apache-2.0

// Package spec publishes the attestation format's JSON Schema as data a Go
// program can embed, for a consumer that validates against the schema
// rather than importing the verifier — a policy engine with its own schema
// validator, or a test that a statement written by something else still
// conforms.
//
// The file is generated from the attestation package's types by
// scripts/specgen, and CI fails when it drifts; the bytes here are the same
// bytes as spec/attestation/mcp-evaluation-v1.schema.json in the repository.
package spec

import _ "embed"

// AttestationSchema is JSON Schema 2020-12 for an in-toto Statement carrying
// the mcp-evaluation/v1 predicate.
//
//go:embed attestation/mcp-evaluation-v1.schema.json
var AttestationSchema []byte
