// SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
// SPDX-License-Identifier: Apache-2.0

package spec

import (
	"encoding/json"
	"testing"

	"github.com/sebastienrousseau/scout-reporting/attestation"
)

// The embedded schema is the published one: it parses, it is the 2020-12
// dialect, and its $id names the predicate the attestation package writes.
func TestEmbeddedSchemaIsThePublishedOne(t *testing.T) {
	var s struct {
		Schema string         `json:"$schema"`
		ID     string         `json:"$id"`
		Ref    string         `json:"$ref"`
		Defs   map[string]any `json:"$defs"`
	}
	if err := json.Unmarshal(AttestationSchema, &s); err != nil {
		t.Fatalf("the embedded schema is not JSON: %v", err)
	}
	if s.Schema != "https://json-schema.org/draft/2020-12/schema" {
		t.Errorf("dialect %q", s.Schema)
	}
	if s.ID != attestation.PredicateType+"/schema.json" {
		t.Errorf("$id %q does not name the predicate %q", s.ID, attestation.PredicateType)
	}
	if s.Ref != "#/$defs/Statement" || s.Defs["Statement"] == nil || s.Defs["Evaluation"] == nil {
		t.Errorf("the root is not the Statement: ref %q, %d definitions", s.Ref, len(s.Defs))
	}
}
