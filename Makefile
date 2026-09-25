# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0

.PHONY: all build test test-race coverage vet lint format spdx-check spec spec-verify \
        example-check integrations lockstep family api-check help

# Every gate CI runs, in the order the cheap ones fail first.
all: format vet lint spdx-check spec-verify example-check test integrations

build:
	go build ./...

test:
	go test ./... -cover

test-race:
	go test -race -shuffle=on ./...

# The gate is 85% statement coverage in every package with statements.
coverage:
	go test -count=1 -coverprofile=coverage.out ./...
	go tool cover -func=coverage.out | tail -1

vet:
	go vet ./...

lint:
	golangci-lint run ./...

format:
	gofmt -l -w .

spdx-check:
	go run ./scripts/spdx_sweep.go

# The published schema is generated from the attestation types.
spec:
	go run ./scripts/specgen/main.go

spec-verify:
	go run ./scripts/specgen/main.go -check

example-check:
	go vet ./examples/... && go run ./examples/verify attestation/testdata/statement.json >/dev/null

# The nested modules under integrations/ are programs built from this
# checkout; ./... from the root does not see them, so they get their own
# gate with the same linter configuration.
integrations:
	cd integrations/agentgateway-extmcp && go vet ./... && go test ./... -cover && golangci-lint run --config ../../.golangci.yml ./...
	# Installable as published: no replace, and a module-mode build succeeds.
	! grep -q '^replace' integrations/agentgateway-extmcp/go.mod
	cd integrations/agentgateway-extmcp && GOWORK=off go build ./...

# This repository carries scout's version. See docs/ecosystem.md in scout.
lockstep:
	scripts/lockstep.sh

# The family manifest in scout is the single source of what this repository is.
family:
	scripts/family.sh

api-check:
	@tag=$$(git describe --tags --abbrev=0 2>/dev/null || true); \
	if [ -z "$$tag" ]; then echo "api-check: no release tag yet, nothing to compare"; exit 0; fi; \
	out=$$(go run golang.org/x/exp/cmd/gorelease@latest -base="$$tag" 2>&1); rc=$$?; \
	printf '%s\n' "$$out"; \
	if printf '%s' "$$out" | grep -qiE 'incompatible changes'; then \
	  echo "api-check: the public API changed incompatibly against $$tag"; exit 1; \
	fi; \
	echo "api-check: no incompatible change against $$tag"

help:
	@printf '%s\n' "targets: all build test test-race coverage vet lint format spdx-check spec spec-verify example-check integrations lockstep family api-check"
