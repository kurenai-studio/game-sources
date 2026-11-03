#!/usr/bin/env bash
set -Eeuo pipefail

tool_manifest="/workspace/.config/dotnet-tools.json"

if [ -f "${tool_manifest}" ]; then
    dotnet tool restore --tool-manifest "${tool_manifest}" --verbosity quiet
fi

exec "$@"
