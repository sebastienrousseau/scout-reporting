// SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
// SPDX-License-Identifier: Apache-2.0

// Command verify is the smallest consumer of a scout attestation: it reads
// one from a file, checks it offline, and prints the score and every
// failing check. It is what a gateway's admission hook does before it
// decides anything, and it needs nothing but the standard library and the
// attestation package.
//
//	go run ./examples/verify attestation/testdata/statement.json
package main

import (
	"fmt"
	"os"

	"github.com/sebastienrousseau/scout-reporting/attestation"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: verify <statement.json>")
		os.Exit(2)
	}
	b, err := os.ReadFile(os.Args[1]) // #nosec G304 G703 -- the file the operator named on the command line
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	st, err := attestation.Parse(b)
	if err != nil {
		fmt.Fprintln(os.Stderr, "not a scout attestation:", err)
		os.Exit(1)
	}
	if err := st.Validate(); err != nil {
		fmt.Fprintln(os.Stderr, "invalid:", err)
		os.Exit(1)
	}
	p := st.Predicate
	score := "no score"
	if p.Score != nil {
		score = fmt.Sprintf("score %.0f/100 (%s) under rubric %s", p.Score.Total, p.Score.Grade, p.JudgedAgainst.Rubric)
	}
	fmt.Printf("%s %s — %s; judged against MCP %s by %s %s; %d pass, %d warn, %d fail, %d skip\n",
		p.Target.Transport, p.Target.Endpoint, score, p.JudgedAgainst.SpecRevision,
		p.Instrument.Name, p.Instrument.Version, p.Counts.Pass, p.Counts.Warn, p.Counts.Fail, p.Counts.Skip)
	for _, v := range p.Verdicts {
		if v.Status == "fail" {
			fmt.Printf("  fail  %-8s %-40s %s\n", v.Severity, v.ID, v.Doc)
		}
	}
}
