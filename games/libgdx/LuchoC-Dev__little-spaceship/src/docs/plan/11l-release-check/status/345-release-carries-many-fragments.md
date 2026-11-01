# 345 — pre-pr-check fails every release, the half #177 did not reach

**Branch:** `fix/release-carries-many-fragments`. **Closes:** [#345](https://github.com/LuchoC-Dev/little-spaceship/issues/345).
Written by the coordinator, on `tools/pre-pr-check` only.

## What was wrong

Opening the `dev` → `main` release pull request for phases 11h–11k
([#344](https://github.com/LuchoC-Dev/little-spaceship/pull/344)) turned `pr-check` red:

```
pass branch name: dev against main — the release, and the one time dev is a head
FAIL 60 status fragments in one branch; a task writes exactly one
```

The status-fragment check had two cases — `phase/*`, which accepts one fragment per task, and
everything else, which demands exactly one. **`dev` fell into "everything else".** A release carries
every fragment of every phase merged since the last one, so it was being measured against a rule that
belongs to a sub-branch.

## Why it is the second half of #177

[#177](https://github.com/LuchoC-Dev/little-spaceship/issues/177) was *"`pr-check` fails every
`dev` → `main` release"*, and phase 11d fixed it — but only for the **branch-name** check, whose
comment at `tools/pre-pr-check:62` explains at length that a release is `dev` as a head against
`main`. The fragment check never learned the same thing.

**#177's own record is the tell.** It notes that the issue described one failure and there were two,
because `.github/workflows/pr-check.yml` exits at its first step and the later step had never run.
**This is a third instance of that pattern**: a check that had never been observed on a release,
because the release before it failed earlier for a different reason. Each fix reveals the next one,
and the only way to see them is to run a release.

## The fix

A `dev)` case in the fragment check, mirroring the branch-name check's structure and its narrowness:
`main` or `origin/main` as the base passes and names the count; **any other base fails**, so `dev`
against anything else does not acquire an exemption on the way past. The comment says why, and dates
it.

## Verification

Every case run by hand on this branch.

- **The release passes.** `tools/pre-pr-check --base origin/main --branch dev --no-build`, standing
  on `dev`: `pass 60 status fragment(s), one per task of every phase in this release`.
- **`dev` against anything else still fails**, and does not reach the new pass.
- **A sub-branch with two fragments still fails**, so the rule this exemption is carved out of is
  intact.
- **A phase branch still passes** with one fragment per task.
- **This branch's own check** is in the pull request.

## What it leaves open

**Nothing checks the release path except running a release.** Three defects have now been found in it
this way — #177's two halves and this — each hidden behind the previous one. A release happens rarely
enough that the next instance will also be found by a human opening a pull request and reading a red
check. Worth an issue if a fourth appears; not worth building a harness for on three data points.
