# Phase 11l — the check that fails every release · status

**State:** **done, and on `dev`.** Merged in [#348](https://github.com/LuchoC-Dev/little-spaceship/pull/348)
on 06/09/2026, with the project owner's direct approval.
**Updated:** 06/09/2026

One defect, found by doing the thing it breaks.

## Why this phase exists

**It was found by opening the release.** Phase 11k closed, `dev` went three phases ahead of `main`,
and the `dev` → `main` pull request ([#344](https://github.com/LuchoC-Dev/little-spaceship/pull/344))
turned `pr-check` red:

```
pass branch name: dev against main — the release, and the one time dev is a head
FAIL 60 status fragments in one branch; a task writes exactly one
```

It is a phase rather than a loose branch because 11k was already merged and closed, and **branching
from `dev` happens for one reason only: to open a phase.** A one-task phase is a shape this project
has used before — 11g was two things the 11 group left behind.

## Done

| Task | Issue | What | PR |
|---|---|---|---|
| 1 | [#345](https://github.com/LuchoC-Dev/little-spaceship/issues/345) | A release carries a fragment per task of every phase in it | [#346](https://github.com/LuchoC-Dev/little-spaceship/pull/346) |

## What it is, and why it had never been seen

`tools/pre-pr-check`'s status-fragment check had two cases: `phase/*`, which accepts one fragment per
task, and everything else, which demands exactly one. **`dev` fell into "everything else"**, and a
release carries every fragment of every phase merged since the last one.

**It is the half of [#177](https://github.com/LuchoC-Dev/little-spaceship/issues/177) that fix did
not reach.** #177 was *"`pr-check` fails every `dev` → `main` release"* and phase 11d fixed it — for
the **branch-name** check, whose comment at `tools/pre-pr-check:62` explains at length that a release
is `dev` as a head against `main`. The fragment check never learned it.

**#177's own record predicted this.** It noted that the issue described one failure and there were
two, because `.github/workflows/pr-check.yml` exits at its first step and the later step had never
run. This is the **third** instance of that pattern: a check never observed on a release, because the
release before it failed earlier for a different reason. Each fix uncovers the next.

## Verified, all four cases by hand

| case | result |
|---|---|
| the release | `pass 61 status fragment(s), one per task of every phase in this release` |
| `dev` against a base that is not `main` | `FAIL the work is on 'dev' itself, so its fragments cannot be judged` |
| a phase branch | `pass 1 status fragment(s), one per task of this phase` |
| a sub-branch with two fragments | `FAIL 2 status fragments in one branch; a task writes exactly one` |

The last is the rule this exemption is carved out of, and it was produced by committing a second
fragment, running the check and resetting it away.

## Two coordinator errors, recorded rather than corrected quietly

**This file's first version was committed directly on the phase branch**, which the regime forbids —
the coordinator reaches a phase branch by merging, never by committing. **Phase 11g and phase 11h
each recorded the same error**, on 02/09 and 03/09, and this is the third time. No tool catches it:
`pre-pr-check` runs on a branch about to open a pull request, and a commit straight onto the phase
branch never opens one. That is the whole difference between a rule a tool enforces and a rule
someone has to remember, and this one is still the second kind. The commit stands — history is not
rewritten here — and this paragraph reached the file the way it should have in the first place.

**The fix was first opened as a `fix/` branch straight against `dev`**, which the regime forbids —
only a phase branch or a documentation branch opens against `dev`. `pr-check` caught it
(`FAIL only a phase branch or a docs branch opens against dev`), which is the mechanism working
exactly as 10d intended: a rule that a tool enforces rather than one someone has to recall. The
branch was retargeted at this phase and its fragment moved here.

## What is open

**Nothing checks the release path except running a release.** Three defects have now been found in it
this way, each hidden behind the previous one. A release happens rarely enough that the next instance
will also be found by a human reading a red check. Not worth a harness on three data points; worth an
issue if a fourth appears.
