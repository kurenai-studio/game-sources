# 137 — The issue contract and the memory-commit subject

**Task 3** · closes [#137](https://github.com/LuchoC-Dev/little-spaceship/issues/137) and [#132](https://github.com/LuchoC-Dev/little-spaceship/issues/132) · branch `build/commit-msg-hook`

## A correction to the issue: it asked for the wrong hook

Both #137 and #132 say *"the `pre-commit` hook rejects a malformed subject"*. **`pre-commit` cannot do that.** It runs before the message exists and git passes it no message — the subject only becomes available to `commit-msg`, which receives the path to the message file as its first argument. Writing the check into `pre-commit` would have produced a hook that silently never fired, which is worse than no hook.

So `tools/hooks/commit-msg` is new, alongside the existing `pre-commit`. `tools/install-hooks` needed no change: it sets `core.hooksPath=tools/hooks`, so every hook in that directory is picked up, including ones added later.

## What it checks, and why on every commit

Every commit's subject: one of the eleven types, an optional scope of `[a-z0-9._-]` with **no spaces**, a description, and 71 characters or fewer. Merges, reverts, `fixup!`, `squash!` and an empty or comment-only message are skipped.

**Corrected on 28/08/2026.** This paragraph originally said the hook checks "against the same rule `tools/pre-pr-check` applies". That was false for four of those five exemptions: `pre-pr-check` skipped only `Merge `, so `git revert`'s own wording passed the hook and failed the gate. It was written by testing the hook and never the gate. `reviewer` found it auditing the phase; [#154](https://github.com/LuchoC-Dev/little-spaceship/issues/154) makes the parity real by giving both callers one shared rule, and `status/154-one-subject-rule.md` records what changed.

**Not only memory commits**, although memory is what motivated it. A rule with one exception is a rule someone has to remember the boundary of, and this phase exists because rules that depend on remembering get broken.

## Why a hook and not the existing check

`pre-pr-check` already validates subjects — but only over a sub-branch's own commits, and **agent-memory commits are in no sub-branch**. The `pre-commit` hook next to this one forces `.claude/agent-memory/` to be committed from the main checkout, which sits on the phase branch, so those commits appear in no sub-branch's diff. Nothing looked at them until the phase-level `pre-pr-check --base dev`, once, at the end.

Phase 11b paid the bill: three agents wrote three different malformed scopes, and by the time anything noticed they sat 55 commits deep in a branch about to open against `dev`. Correcting three subjects cost a history rewrite, an explicit exception from the project owner to a rule that forbids force-pushing, and corrections to three closed issues whose cited merge hashes the rewrite destroyed.

## Verified by running it, not by reading it

Against message files, all three cases:

| Subject | Result |
|---|---|
| `docs(core-domain memory): record something` | rejected, exit 1, with the guidance naming `docs(memory):` |
| `docs(memory): record something` | accepted, exit 0 |
| `Merge pull request #1 from x/y` | accepted, exit 0 |

And live, on this branch: `git commit -m "docs(core-domain memory): probe the hook"` was **refused**, with `git log` confirming the tip unchanged at the previous merge.

## One thing `pre-pr-check` caught on the way

The first attempt to open this pull request went red: `tools/hooks/commit-msg is mode 100644`. `chmod +x` in Git Bash on Windows does not set the index bit, so the hook would have arrived at a Linux runner unexecutable — the same failure that killed phase 09's first two CI runs and the reason that check exists. Fixed with `git update-index --chmod=+x`.

## The written half

- `CLAUDE.md` — the scope charset, the `docs(memory):` form, the one-issue-per-pull-request contract with the coordinator's documentation pull requests as the named exception, and the status-fragment rule. Plus why the `commit-msg` hook exists: for an agent-memory commit it is the only check that runs before the phase closes.
- `docs/plan/how-to-run-a-phase.md` — the **Issue** step now covers defects found while the phase runs, which "one per task in the plan" did not.
- All six definitions under `.claude/agents/` — the scope rule, the memory form, and the fragment replacing the shared `status.md` as the place a task records itself. Two of them (`level-designer`, `reviewer`) word their commit sections differently and were edited individually rather than by pattern.

## Open

Nothing here. `#132` is closed by this task.
