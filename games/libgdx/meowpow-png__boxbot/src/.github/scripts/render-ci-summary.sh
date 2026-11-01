#!/usr/bin/env bash

set -euo pipefail

template="${1:-.github/templates/ci-summary.md}"
: "${TESTS_PASSED:?TESTS_PASSED is required}"
: "${COVERAGE:?COVERAGE is required}"
: "${GITHUB_STEP_SUMMARY:?GITHUB_STEP_SUMMARY is required}"

envsubst '${TESTS_PASSED} ${COVERAGE}' < "$template" >> "$GITHUB_STEP_SUMMARY"
