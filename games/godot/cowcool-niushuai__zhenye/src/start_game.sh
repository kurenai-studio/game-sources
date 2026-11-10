#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="${GODOT_BIN:-$HOME/.local/bin/godot-4.7.1}"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zhenye"

if [[ ! -x "$GODOT_BIN" ]]; then
	message="找不到 Godot：$GODOT_BIN"
	if command -v kdialog >/dev/null 2>&1; then
		kdialog --error "$message"
	else
		printf '%s\n' "$message" >&2
	fi
	exit 1
fi

if pgrep -f -- "[Gg]odot.*--path ${PROJECT_DIR}$" >/dev/null; then
	exit 0
fi

mkdir -p "$LOG_DIR"
nohup "$GODOT_BIN" --path "$PROJECT_DIR" >"$LOG_DIR/game.log" 2>&1 &
