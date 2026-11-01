# Phase 10b — Agents and the way sessions are run · status

**State:** done and merged — the phase branch reached `dev` in PR [#76](https://github.com/LuchoC-Dev/little-spaceship/pull/76) and `main` in PR [#79](https://github.com/LuchoC-Dev/little-spaceship/pull/79), both on 26/08/2026 with the project owner's direct approval
**Updated:** 26/08/2026

Update this file when the phase moves. It is the only place phase progress is recorded — the `plan.md` next to it says what to do and does not change to reflect progress.

This is the first phase run under the branch regime it introduced: everything below landed on
`phase/10b-agents-and-sessions`, one sub-branch and one pull request per issue (#67–#78) merged by the
coordinator, and the phase reached `dev` as a single pull request instead of nine merges into `main`.
The merge into `main` **should not have been made by the coordinator at all.** The owner said "you
can merge to main" and the coordinator did, hours after this phase wrote that `main` is the owner's
merge. It was left in place — the content is what the owner had already approved for `dev`, and no
game code is involved — and the rule was tightened instead: permission does not transfer that merge,
and `main` now requires an approving review on GitHub. See `claude-md-changes.md`, row 8.

## Done

Eight tasks, eight issues, eight pull requests merged into the phase branch (#67–#74).

**Task 1, what phase 09 cost** (issue [#59](https://github.com/LuchoC-Dev/little-spaceship/issues/59),
PR [#69](https://github.com/LuchoC-Dev/little-spaceship/pull/69)) —
[`measurement.md`](measurement.md). Summed from the session transcript and its eight subagent
transcripts: **813 model calls, 72.3 M cache-read tokens, $110.76** at public API rates. The
coordinator is 38 % of the calls and **83 % of the cost**, because it ran on Opus while every
subagent ran on Sonnet. `reviewer` on Sonnet held, 4 of 4. Zero spend limits, against fourteen in the
audited period. Two thirds of the cost is still re-reading history — the regime cut the total and did
not change the shape. A call at the end of the phase cost 2.3× a call at its start, two hours apart.

**Task 2, the six agent definitions** (issue [#60](https://github.com/LuchoC-Dev/little-spaceship/issues/60),
PR [#74](https://github.com/LuchoC-Dev/little-spaceship/pull/74)) — [`agent-audit.md`](agent-audit.md).
`level-designer` had no `memory: project`, so 141 lines of its memory had never been loaded;
`reviewer` said "You change nothing" while having to commit its own memory, which ended two of four
phase 09 reviews in memory logistics; the roster in `13-working-with-agents.md` listed five agents and
argued that the sixth had been deliberately not created (F27). Three findings were deliberately **not**
turned into rules, with the reason written down.

**Task 3, the memory-path trap** (issue [#61](https://github.com/LuchoC-Dev/little-spaceship/issues/61),
PR [#70](https://github.com/LuchoC-Dev/little-spaceship/pull/70)). `tools/agent-memory-path <agent>`
prints the canonical directory from any worktree; `tools/hooks/pre-commit` refuses a commit staging
`.claude/agent-memory/` from a linked worktree; `core.hooksPath` makes one install cover every
worktree, including later ones. **Tested by a `test-engineer` working from a real worktree** and told
to try to walk around it: refused on `git add`, `git commit -a`, a nested subdirectory, a mixed
commit, `--amend`, and a worktree created after the install. The hook then caught a defect in itself —
`--absolute-git-dir` answers `C:/…` on Windows while the common dir resolves to `/c/…`.

**Task 4, the "verified" failure** (issue [#62](https://github.com/LuchoC-Dev/little-spaceship/issues/62),
PR [#71](https://github.com/LuchoC-Dev/little-spaceship/pull/71)) — [`evidence.md`](evidence.md). A
claim about a system cites an observation of that system; with no observation, write **"not
checked"**, which is always acceptable. `tools/pre-pr-check` lists added markdown lines shaped like an
unobserved claim without failing on them. Checked against the real commit that carried phase 09's
false sentence, `4e11d87`, which it does flag — after being fixed, because the sentence wraps across
two lines and a line-by-line grep missed it.

**Task 5, nine phases of agent memory** (issue [#63](https://github.com/LuchoC-Dev/little-spaceship/issues/63),
PR [#73](https://github.com/LuchoC-Dev/little-spaceship/pull/73)) — [`memory-audit.md`](memory-audit.md).
46 files, 2,142 lines, every backticked reference resolved against the repository. **Nothing deleted,
two files corrected**: `core-deferred-surface.md`, the one file that keeps an inventory of what was
built in which phase — forbidden by `CLAUDE.md` — and the only one that rotted; and the reviewer's
`review-tooling-and-memory-placement.md`, which taught the memory-path trap as a technique.

**Task 6, where a correction goes** (issue [#64](https://github.com/LuchoC-Dev/little-spaceship/issues/64),
PR [#72](https://github.com/LuchoC-Dev/little-spaceship/pull/72)). Back to the worker only while it is
still open and the fix is inside what it just did; once closed it stays closed, and the work becomes a
new issue against the state in Git; the coordinator takes prose fixes of one or two files, which is
what both phase 09 rejections were. The limit: a third correction absorbed in one phase means the plan
is defective, not the work.

**Task 7, the branch regime** (issue [#65](https://github.com/LuchoC-Dev/little-spaceship/issues/65),
PR [#68](https://github.com/LuchoC-Dev/little-spaceship/pull/68)). `main` ← `dev` ←
`phase/<phase>-<description>` ← `type/description`. Nothing is committed on `main` or `dev`; only the
project owner merges `dev` into `main`; an agent opens a pull request and **merges nothing**. Written
into `CLAUDE.md`, `how-to-run-a-phase.md`, `13-working-with-agents.md` and all six agent definitions.

**Task 8, the pre-PR check** (issue [#66](https://github.com/LuchoC-Dev/little-spaceship/issues/66),
PR [#67](https://github.com/LuchoC-Dev/little-spaceship/pull/67)). `tools/pre-pr-check`, ten checks and one
non-failing note, no tokens. **It caught a real defect on its first run, on itself** — committed mode `100644`, the same
failure that killed phase 09's first two CI runs.

**`CLAUDE.md`** carries six edits, each justified in [`claude-md-changes.md`](claude-md-changes.md),
which is the plan's condition for touching that file.

## In progress

Nothing.

## Blocked

Nothing.

## Decisions taken while implementing

- **The git workflow came back into scope**, by the project owner on 26/08/2026, after the phase had
  started. `plan.md`'s out-of-scope bullet is struck through and tasks 7 and 8 were added. What stays
  out is worktree *ergonomics* — creating and cleaning them up is still by hand.
- **The check is a script, not a checklist**, and the claim detector inside it **warns rather than
  fails**. Every phrase it matches is legitimate when true, and a check that failed on `CLAUDE.md`'s
  own "headless Chrome cannot validate the web runtime" would be switched off within a phase.
- **Nothing in agent memory was deleted.** The one file that broke the rule holds the only copy of
  reasoning that exists nowhere else; deleting the duplicate would have taken the original with it.
- **Three candidate rules were rejected on cost**, and the reasons are in `agent-audit.md`. Every rule
  added is read by every agent on every phase, which is the finding that produced this regime.

## Notes for whoever comes next

- **The issues are still open on GitHub.** A pull request merged into a phase branch does not close
  its issue — GitHub only auto-closes on the default branch. #59–#66 are closed by hand with a comment
  naming their pull request.
- **`tools/install-hooks` is per clone.** A fresh clone of this repository has no hooks until someone
  runs it once. `tools/pre-pr-check` reports the same condition the hook does, so a missed install is
  caught at the pull request rather than at the commit.
- **Who merges a phase into `dev`**: a coordinator or lead may, **only with the project owner's
  direct approval on that pull request**, and approval of one phase does not carry to the next. This
  was the one gap in the regime as first written; the owner answered it on 26/08/2026 and it is in
  `CLAUDE.md`, `how-to-run-a-phase.md` and `13-working-with-agents.md` (PR #77).
- **The measurement's biggest number is a model choice, not a workflow.** Running a coordinator on
  Opus cost roughly five times what the same traffic on Sonnet would have. Phase 10c is the next
  chance to test whether "Sonnet coordinates; Opus decides" can actually be followed, given that this
  project has broken it in every phase measured so far — including this one.
