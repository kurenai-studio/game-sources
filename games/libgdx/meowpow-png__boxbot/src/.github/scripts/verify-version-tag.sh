#!/usr/bin/env bash

set -euo pipefail

ref="${1:?Usage: verify-version-tag.sh <ref-name>}"

if [[ ! "$ref" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?$ ]]; then
  echo "::error::'$ref' is not a version tag (expected vX.Y.Z or vX.Y.Z-rc.N) — refusing to release from a branch."
  exit 1
fi
