#!/usr/bin/env bash
# Abre o Tux Obby 3D. Defina GODOT_BIN se o executável do Godot não estiver no PATH.
set -euo pipefail
cd "$(dirname "$0")"
exec "${GODOT_BIN:-godot}" --path . "$@"
