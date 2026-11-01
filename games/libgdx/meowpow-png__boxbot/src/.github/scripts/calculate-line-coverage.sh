#!/usr/bin/env bash

set -euo pipefail

report="${1:-core/build/reports/jacoco/test/jacocoTestReport.xml}"
line_counter=$(grep -oE '<counter type="LINE" missed="[0-9]+" covered="[0-9]+"/>' "$report" | tail -n 1)
missed=$(sed -E 's/.*missed="([0-9]+)".*/\1/' <<< "$line_counter")
covered=$(sed -E 's/.*covered="([0-9]+)".*/\1/' <<< "$line_counter")
coverage=$(awk -v missed="$missed" -v covered="$covered" 'BEGIN { printf "%.2f%%", 100 * covered / (missed + covered) }')
tests_passed=$(find core lwjgl3 -path '*/build/test-results/test/*.xml' -type f -exec awk '
  function attribute(name, value) {
    value = $0
    sub(".* " name "=\"", "", value)
    sub("\".*", "", value)
    return value
  }

  /<testsuite / {
    total += attribute("tests")
    skipped += attribute("skipped")
    failures += attribute("failures")
    errors += attribute("errors")
  }

  END { print total - skipped - failures - errors }
' {} +)
: "${tests_passed:?No JUnit test result files found}"
color="$(awk -v coverage="${coverage%%%}" 'BEGIN {
  if (coverage >= 80) print "brightgreen"
  else if (coverage >= 60) print "yellow"
  else print "red"
}')"

echo "percentage=$coverage" >> "$GITHUB_OUTPUT"
echo "tests_passed=$tests_passed" >> "$GITHUB_OUTPUT"
echo "color=$color" >> "$GITHUB_OUTPUT"
