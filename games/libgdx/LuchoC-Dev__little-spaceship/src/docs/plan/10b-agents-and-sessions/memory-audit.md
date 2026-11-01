# The agent-memory audit

Task 5 of [`plan.md`](plan.md), run on 26/08/2026. Nine phases of accumulation, never looked at as a
whole. **46 files, 2,142 lines**, across six directories under `.claude/agent-memory/` — counted with `wc -l` after this phase's own corrections landed, two of those files written today.

`CLAUDE.md` sets the test: memory holds what the repository has no reason to record, and **never
phase progress**, "because when both hold it, one of them silently rots".

## How each file was judged

Three questions, in this order, because they have different answers:

1. **Is it still true?** Every backticked type, member and path in every memory file was extracted and
   resolved against the repository, the same shape of check `docs-refs` will do for `docs/`
   ([#56](https://github.com/LuchoC-Dev/little-spaceship/issues/56)). Around thirty came back
   unresolved; all but four are libGDX or JDK names, `SystemOrder` enum constants, branch names, or
   deliberate references to things that do not exist.
2. **Does it duplicate `docs/`?** A memory that restates the spec makes a seventh source of truth.
3. **Is it phase progress?** The one thing the rule forbids outright.

## Verdict by directory

| Directory | Files | Lines | Verdict |
|---|---:|---:|---|
| `core-domain/` | 13 | 569 | **Keep, one corrected.** Mostly rationale that exists nowhere else — why `Health` was missed, why no `BossPart` component, why patterns stayed deferred. `core-deferred-surface.md` is the exception and is the audit's main finding |
| `game-presentation/` | 17 | 583 | **Keep, all of it.** The densest useful directory in the repository: `BitmapFont.draw`'s y is a top not a baseline, the AngelCode `metrics` line silently dropped without a preceding `kernings count=`, `du -sh` overstating a TeaVM dist, the release-build caching trap. None of it is derivable from the code |
| `level-designer/` | 3 | 141 | **Keep, but nothing has ever read it** — see the finding below |
| `reviewer/` | 4 | 643 | **Keep, one corrected.** `defect-patterns.md` is 452 lines and worth every one; its pattern 4 predicted this audit's main finding two months early |
| `visual-designer/` | 7 | 187 | **Keep.** Palette and silhouette decisions with the reasoning attached. Its file paths are written relative to `docs/design/`, which is imprecise but not wrong |
| `test-engineer/` | 2 | 19 | **New today.** Empty until phase 10b, which is finding F32 of the 10a audit; it now holds the verification of the memory-path hook |

## The findings

### M1 — `core-domain/project_core-deferred-surface.md` is phase progress, and it rotted · corrected

The file lists, entry by entry, what was **built in which phase**. That is `status.md`'s job by an
explicit rule, and the file's own last line says so — "Current implementation state — what phase added
what — lives in `docs/plan/*/status.md`, not here" — directly under sixty lines of exactly that.

Two entries are false as of today:

- "Concrete `GameEvent` implementations — **still deferred as of phase 07**". `EnemyDestroyed` exists
  in `core/domain/event/`.
- "`enemy-shooter`'s higher rate of fire is still unbuilt — no `"weapon"` factory for enemies exists".
  `ComponentFactoryRegistry` registers `"weapon"`, the component is `EnemyWeapon`, and all six
  archetypes in `assets/data/enemies.json` declare one.

The file had already been wrong once, and says so about its own `Health` entry. That is the second
occurrence of one failure, not two failures.

**Corrected rather than deleted.** The *reasons* are genuine memory and exist nowhere else — why a
`GameEvent` was not invented for the boss-music hook, why `PatternDefinition` still has no second
case. The two stale claims are struck through and answered, and a dated note at the top says to read
the file for **why** something was left out and never for **whether** it still is.

### M2 — `reviewer/project_review-tooling-and-memory-placement.md` taught the trap · corrected

It said, as guidance to every future reviewer:

> "memory belongs in the worktree being audited … write the *superset*: read
> `git show main:.claude/agent-memory/reviewer/<file>` first and add to that, so the merge cannot
> silently revert the newer text."

That is the memory-path trap written down as a technique, complete with a workaround for the symptom
it causes. It is also honest about its own history — "putting it in the main worktree once left a
dirty `main` that had to be rescued" — which is how a workaround becomes doctrine.

Struck through and replaced with what issue #61 decided: one home, `tools/agent-memory-path reviewer`
prints it, the hook refuses anything else. The superset dance is unnecessary once there is a single
revision.

### M3 — `level-designer` writes memory that no instance can read · handed to task 2

`level-designer.md` has no `memory: project` in its frontmatter. Its three memory files — including
107 lines on where a formation actually lands and `offsetY` being a head start in pixels rather than
seconds — have never been loaded by any instance of that agent, and its own prompt tells it to keep
writing them.

Recorded here, fixed in [#60](https://github.com/LuchoC-Dev/little-spaceship/issues/60), which owns
the agent definitions.

### M4 — the CI memory file is what the rule is supposed to produce · keep, untouched

`game-presentation/project_github-actions-ci-shape.md` carried the phase 09 false claim, was
corrected, and now carries the countermeasure in the imperative:

> "**A workflow that triggers on `push` has already run by the time you finish writing about it.**
> … Reporting 'never run on a real runner' while four real runs sat in the API is the mistake this
> entry exists to prevent."

That is the shape the rest of this phase is trying to reproduce — a lesson that survives its author,
in the place the next instance will meet it. Named here so it is not lost in a list of verdicts.

## What stays out

Nothing was deleted.

The temptation was `core-deferred-surface.md`, and the reason not to is that its rationale is the only
copy in existence while its phase tracking is a duplicate of something that still exists. Deleting the
file to remove the duplicate would have taken the original with it. Correcting a dated record and
saying when it was corrected is the same treatment `docs/` got in phase 10a, and it is the one that
leaves the reasoning readable.

## What this audit says about the rule

The rule holds and it needs a sharper edge. "Never phase progress" was followed everywhere except in
the one file that made a *list* of it, and that file is the only one that rotted in nine phases. The
signal is not the topic — plenty of memory names phases while explaining a decision, and none of it is
stale. The signal is the **shape**: a file that maintains an inventory has to be maintained, and
nothing maintains it.
