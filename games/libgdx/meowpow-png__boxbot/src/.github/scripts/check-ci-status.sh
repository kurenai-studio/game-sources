#!/usr/bin/env bash

set -euo pipefail

repo="${1:?Usage: check-ci-status.sh <repo> <sha>}"
sha="${2:?Usage: check-ci-status.sh <repo> <sha>}"

conclusion=$(gh run list --repo "$repo" --workflow ci.yml \
  --commit "$sha" --json conclusion --jq '.[0].conclusion // "missing"')

if [ "$conclusion" != "success" ]; then
  echo "::error::CI has not succeeded for commit $sha (found: $conclusion)"
  exit 1
fi
