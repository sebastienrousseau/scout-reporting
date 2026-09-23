#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Sebastien Rousseau <sebastian.rousseau@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
# Fail unless CHANGELOG.md has a heading for the version being released and
# the install snippet in README.md does not pin a stale version.
#
#   scripts/verify-release-versions.sh v0.0.4
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
tag="${1:-${GITHUB_REF_NAME:-}}"
[ -n "$tag" ] || { echo "usage: $0 vX.Y.Z" >&2; exit 2; }
ver="${tag#v}"
grep -Eq "^## \[$ver\]" CHANGELOG.md || { echo "CHANGELOG.md has no '## [$ver]' heading" >&2; exit 1; }
if grep -Eo 'scout-reporting@v[0-9]+\.[0-9]+\.[0-9]+' README.md | grep -v "scout-reporting@v$ver"; then
  echo "README.md pins a version other than $ver" >&2; exit 1
fi
echo "release versions agree on $ver"
