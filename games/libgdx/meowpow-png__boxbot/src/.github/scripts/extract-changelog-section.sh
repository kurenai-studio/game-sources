#!/usr/bin/env bash

set -euo pipefail

version="${1:?Usage: extract-changelog-section.sh <version> [changelog-file]}"
changelog="${2:-CHANGELOG.md}"

# RC tags preview [Unreleased] since nothing's been dated yet; final tags read the
# section promoted to their own version heading (done by hand before tagging).
if [[ "$version" == *-rc.* ]]; then
  heading="Unreleased"
else
  heading="$version"
fi

awk -v heading="$heading" '
  $0 ~ ("^## \\[" heading "\\]") { found = 1; next }
  /^## \[/ { if (found) exit }
  /^\[.*\]:/ { if (found) exit }
  found
' "$changelog"
