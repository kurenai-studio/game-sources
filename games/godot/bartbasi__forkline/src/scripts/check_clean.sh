#!/usr/bin/env bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# Checks that the folder is a git checkout with no uncommitted work, so a build
# is made from exactly the commit it names. Run from any folder, in Git Bash:
#   scripts/check_clean.sh
#
# "Uncommitted work" means a changed tracked file, or an untracked file that git
# does not ignore. Ignored files (build/, .godot/, android/) do not count.
# build.sh and build_release.sh run this first.
#
# Exit code 0: clean. It prints the commit that a build would use.
# Exit code 1: not clean, or git could not tell. It lists up to 15 changes.
# Exit code 2: this folder is not a git checkout (no .git), so nothing can be
#              checked. A copy made with "git archive" is like that.

set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -e "$root/.git" ]; then
	echo "This folder is not a git checkout, so the tree cannot be checked."
	exit 2
fi
command -v git > /dev/null 2>&1 || { echo "git was not found, so the tree cannot be checked."; exit 1; }

changes="$(git -C "$root" status --porcelain 2> /dev/null)" || { echo "git status failed, so the tree cannot be checked."; exit 1; }
if [ -n "$changes" ]; then
	count="$(printf '%s\n' "$changes" | wc -l | tr -d ' ')"
	echo "The working tree has $count uncommitted change(s):"
	printf '%s\n' "$changes" | head -n 15
	[ "$count" -le 15 ] || echo "... and $(( count - 15 )) more."
	echo "A published build must come from a commit. Commit the work, or build from a clean clone of the commit."
	exit 1
fi

echo "Working tree is clean. Commit: $(git -C "$root" rev-parse HEAD)"
exit 0
