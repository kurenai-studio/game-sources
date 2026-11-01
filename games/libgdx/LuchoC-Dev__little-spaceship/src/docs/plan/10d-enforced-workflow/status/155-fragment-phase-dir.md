# 155 — A fragment in the wrong phase's directory

**Found by `reviewer`, auditing the phase** · closes [#155](https://github.com/LuchoC-Dev/little-spaceship/issues/155) · branch `fix/fragment-phase-dir`

## The defect

Both checks verified a fragment's **basename** against the issue number and neither verified **which phase's directory it sat in**. A branch against `phase/10d-enforced-workflow` adding `docs/plan/11c-movement-shapes/status/999-misplaced.md` passed both.

`reviewer` found it by building the shape rather than reading for it, which is why it was found at all: nothing about the code looks wrong until you try to put a fragment in the wrong place.

The consequence is quiet. One phase's work gets recorded in another phase's status, and the phase it belongs to ends up **silently short** — the same failure [#136](https://github.com/LuchoC-Dev/little-spaceship/issues/136) exists to prevent, arriving through a different door.

## The fix

`tools/status-fragments --misplaced <base-ref>` prints the added fragments that are **not** under the directory the base branch names. The derivation is direct: a branch opened against `phase/<phase>-<description>` belongs to `docs/plan/<phase>-<description>/status/`.

A branch opened against `dev` is exempt — `dev` names no phase to compare against, and a phase branch's fragments are all in its own directory anyway.

## One implementation, and why that matters here more than usual

This is the third rule in the phase to be given a shared script, after `commit-subject-ok` and the fragment listing itself. The reason is no longer theoretical: **the same rule written twice drifted twice in one afternoon**, the second time inside the pull request whose subject was the first drift.

So `--misplaced` lives in the same script both callers already use. `tools/pre-pr-check` and `.github/workflows/pr-check.yml` ask the identical code, which means a test of one is a test of the rule — not merely of one copy of it.

## Verified by running it

```
$ tools/status-fragments --misplaced phase/10d-enforced-workflow      # clean branch
[nothing]

$ # after adding docs/plan/11c-movement-shapes/status/999-misplaced.md
$ tools/status-fragments --misplaced phase/10d-enforced-workflow
docs/plan/11c-movement-shapes/status/999-misplaced.md

$ tools/pre-pr-check --base phase/10d-enforced-workflow
FAIL a status fragment sits in another phase's directory
       docs/plan/11c-movement-shapes/status/999-misplaced.md
```

The scratch commit that created the misplaced file was removed afterwards.

## One thing that went wrong while fixing it, worth recording

Removing the scratch file with `rm -rf docs/plan/11c-movement-shapes` deleted **the real `plan.md` and `status.md` of phase 11c** along with it — a directory that legitimately exists and that the next phase is about to use. Caught by `git status` in the same breath and restored with `git checkout --`, so nothing was lost, but the lesson is plain enough to write down: a scratch file created inside a real directory does not come out with a recursive delete of that directory.

The YAML check added in [#150](https://github.com/LuchoC-Dev/little-spaceship/issues/150) also earned its place again in this branch, catching a scripted edit that put a literal newline inside a shell string in `pr-check.yml` — the same class of mistake, the second time, now caught before the commit rather than by GitHub after a merge.

## Open

Nothing. This closes the two gaps the phase's own `reviewer` pass found.
