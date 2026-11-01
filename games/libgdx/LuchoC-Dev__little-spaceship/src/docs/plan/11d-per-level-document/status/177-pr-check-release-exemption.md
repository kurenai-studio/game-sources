# #177 — `pr-check` fails every `dev` → `main` release

**Branch:** `fix/pr-check-release-exemption` · **Closes:** [#177](https://github.com/LuchoC-Dev/little-spaceship/issues/177) · **Written:** 31/08/2026

A defect found before this phase opened, not a task from `plan.md`. It runs here because there is no
sanctioned branch to fix it on: rule 1 of the workflow it breaks accepts only `phase/*` or `docs/*`
against `dev`, and `how-to-run-a-phase.md` provides for a defect found while a phase runs. **Rule 1
was not weakened to let the fix through.**

## Completed

**The defect was two failures, not one, and the second had never been observed.**

`.github/workflows/pr-check.yml` runs two steps. #176 died in the first one, so **the second never
ran** — confirmed in the run log of
[33280307470](https://github.com/LuchoC-Dev/little-spaceship/actions/runs/33280307470), whose last
line is `pr-check: FAIL — 1 check(s) failed.` and which contains no output from
`tools/pre-pr-check` at all. The issue therefore recorded one failure and there were two.

The second was reproduced by hand before it was fixed, standing on `dev`, with the arguments the
workflow passes:

```
$ tools/pre-pr-check --base origin/main --branch dev --no-build
pre-pr-check: branch 'dev' against 'origin/main'

FAIL the work is on 'dev' itself. Branch first; main and dev are never worked on directly.
```

**Both halves are fixed, and the release is named as the third aggregating category.**

| File | What changed |
|---|---|
| `.github/workflows/pr-check.yml` | `IS_RELEASE`, set when the base is `main` and the head is `dev`, exempts the release from rule 2 exactly as `IS_PHASE` exempts a phase branch. Rule 3 gains an explicit release arm |
| `tools/pre-pr-check` | Rule 1's `main\|dev` arm is split. `dev` passes only when the base is `main` or `origin/main`; `main` always fails, and so does `dev` against anything else |

**Rule 3 was checked rather than assumed**, which [#177](https://github.com/LuchoC-Dev/little-spaceship/issues/177)
asked for by name. Two facts, both from reading `tools/status-fragments`: the fragment-name block was
already skipped for a release because it is gated on `ISSUE_COUNT -eq 1`, and the misplaced-fragment
check returns nothing for a `main` base because `--misplaced` exits 0 when the base names no phase
(`case "$BASE" in *phase/*) ... ;; *) exit 0 ;; esac`). Both held by accident rather than by
statement, so a release arm now says so out loud.

## Evidence

**The patched workflow step, run locally on the real body of #176** — the step's `run:` block
extracted verbatim from `pr-check.yml` and executed with the same environment GitHub sets:

```
pr-check: 'dev' into 'main' (event: ready_for_review)

pass base: main, from dev — the project owner merges this one
pass release: dev into main, so it closes no issue of its own
       the issues it carries were closed as each phase merged into dev
pass release: 0 fragment(s), all from phases already merged
pass draft state not checked on 'ready_for_review'; it is only meaningful at opening

pr-check: PASS
```

The `0 fragment(s)` is correct and not a bug: `dev` and `main` are level as this is written, so the
release diff is empty. A release carrying phases has one fragment per task of each of them.

**A regression, because an exemption is where an escape hatch hides.** The same step was extracted
from `dev`'s copy of the file and from the patched one, and both were run over six cases:

| Case | Result |
|---|---|
| task branch into a phase branch, closing one issue | identical to before the patch |
| coordinator's docs-only branch, closing none | identical |
| phase branch into `dev` | identical |
| an illegal base | identical |
| two issues closed | identical |
| **`dev` into `main`** | **the only difference** |

`tools/pre-pr-check` was checked the same way and the narrowing holds: `--base origin/main --branch dev`
now prints `pass branch name: dev against main — the release, and the one time dev is a head`, while
`--base dev --branch dev` — an agent standing on `dev` the ordinary way — still prints
`FAIL the work is on 'dev' itself`.

## Decided, which the issue left open

The issue suggested the release as a third named category and did not decide it. It is decided that
way, and the identification is **the base and head pair and nothing else** — `main` and `dev`, both
exact — which stays inside the limit the project owner set on 28/08/2026: this workflow verifies only
facts checkable without reading prose.

## Open

**Neither half has been observed passing on a real runner yet**, because that needs a `dev` → `main`
pull request and there is nothing to release until this phase group reaches `dev`. The evidence above
is a local execution of the workflow's own code, not a run id. The first real release after this
merges is the observation, and whoever opens it should record the run id here.
