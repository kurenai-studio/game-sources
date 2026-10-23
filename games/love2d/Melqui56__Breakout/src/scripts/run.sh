#!/usr/bin/env bash
# run.sh — Run the Breakout project with LÖVE (Linux/macOS).
set -euo pipefail
cd "$(dirname "$0")/.."
love .
