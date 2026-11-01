---
name: memory-path-hook-verification
description: what verifying issue #61's memory-path fix (tools/agent-memory-path and the pre-commit hook) actually showed
metadata:
  type: project
---

Verified from a linked worktree (`little-spaceship-memory-probe`, branch `test/memory-path-probe`) that the fix for the memory-path trap holds, and tried on purpose to walk around it rather than through it.

**Why:** three hand corrections in phase 09 came from an agent writing `.claude/agent-memory/` into a worktree checkout instead of the main one. Two mechanisms are supposed to close that: `tools/agent-memory-path <agent>` (prints the canonical path via `git rev-parse --git-common-dir`) and a `pre-commit` hook installed through `core.hooksPath`, shared by every worktree of the clone.

**How to apply:**

- `tools/agent-memory-path <agent>` correctly prints the **main checkout's** directory from any worktree, including one created after the hook was already installed — no `tools/install-hooks` re-run needed in a new worktree, because `core.hooksPath` is a clone-wide git config, not a per-worktree one.
- The `pre-commit` hook checks `git diff --cached --name-only` against `^\.claude/agent-memory/`, so it catches the file **regardless of how it got staged**. Confirmed it still refuses when: committing from a nested subdirectory (`cd some/nested/dir && git commit`), `git commit -a` (auto-staging a tracked, already-modified memory file), a memory file staged together with unrelated files in the same commit, and `git commit --amend --no-edit` adding a memory file to an already-made commit. None of these got past it.
- Could not find an accidental way through it without `--no-verify`. The one path not exercised: a merge commit that brings in memory changes from another branch (git skips `pre-commit` for merge commits in general, not specific to this hook) — not a defect in this fix since a merge only carries memory changes that were already committed correctly somewhere else.
- Operational note for Windows: this whole check happens through Git for Windows' bundled `sh.exe`, which fires regardless of the calling shell (Bash tool ran it here; a plain PowerShell `git commit` would hit the same hook the same way, since git spawns the interpreter itself). No PowerShell-specific behavior to special-case.
- Cleanup after probing this: `git reset --hard HEAD~1` plus manually removing untracked probe files was enough to leave the worktree exactly as found — the hook only blocks the commit, it does not leave partial state behind (staged files stay staged, nothing is auto-unstaged).
