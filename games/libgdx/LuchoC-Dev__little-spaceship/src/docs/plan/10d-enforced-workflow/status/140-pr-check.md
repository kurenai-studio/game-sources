# 140 — pr-check: verifying the pull request as an object

**Task 6** · closes [#140](https://github.com/LuchoC-Dev/little-spaceship/issues/140) · branch `ci/pr-check`

## What was done

`.github/workflows/pr-check.yml`, triggered by `pull_request` against any branch. It asserts, in order:

1. **Where the pull request points.** A phase branch takes anything; `dev` takes a phase branch or a docs branch; `main` takes only `dev`.
2. **Exactly one issue closed** — or none, if the diff is documentation only.
3. **A status fragment named for that issue.**
4. **Opened as a draft**, checked only on the `opened` event, because afterwards being ready is the normal end state.

Then, as a separate step, it **runs `tools/pre-pr-check` itself** instead of trusting what was pasted into the description.

## The hole this closes, which #136 could not

`pre-pr-check` exempts any branch whose diff is entirely under `docs/`. That exemption is meant for the coordinator's bookkeeping, but the script cannot tell bookkeeping from documentation work that closes an issue — it runs before the pull request exists and cannot see the issue. Task 4 ([#138](https://github.com/LuchoC-Dev/little-spaceship/issues/138)) landed through exactly that gap: real work, an issue closed, and `pass docs-only branch, so no status fragment is required`. Its fragment was written by convention, not because anything demanded it.

`pr-check` sees the issue, so the rule it applies is the true one: **closes an issue → a fragment named `<issue>-<slug>.md`; closes none → the diff must be documentation only.**

## On duplication, which the issue asked to check first

The issue warned that a workflow firing on both `push` and `pull_request` for the same commit burns double the minutes. It does, so **`ci.yml` was left exactly as it is**: `push` on every branch, `pull_request` on `main` only.

The division that follows:

| | `ci.yml` | `pr-check.yml` |
|---|---|---|
| Fires on | a push to any branch | a pull request against any branch |
| Does | compile, test, and the **real** TeaVM build | the pull-request assertions above |
| Cost | Gradle | seconds, no Java |

`pr-check` therefore passes `--no-build` to `pre-pr-check`, which is new: `tools/pre-pr-check --no-build` skips Gradle and says so, rather than pretending it ran. Nothing is lost, because every commit in a pull request has already been pushed, and `ci.yml` builds it — including `gdx_teavm_web_js_build`, which `./gradlew build` does **not** run at all ([#123](https://github.com/LuchoC-Dev/little-spaceship/issues/123)).

## The limit, kept

Every assertion above is a fact with an exit code: a branch name, an issue number, a file name, a boolean, a script's status. **None of them reads prose.** Whether a description is faithful stays `reviewer`'s work — the project owner set that line and this workflow's header carries it, so the next person adding a check reads the reason before they add one.

## What it found by running on itself

The first run went green on every pull-request assertion and **red on its own last step**: `FAIL branch 'HEAD' is not 'type/description'`.

`actions/checkout` leaves a pull-request checkout **detached**, so `git rev-parse --abbrev-ref HEAD` answers `HEAD`, and `pre-pr-check`'s branch-name check rejects it. Nothing was wrong with the branch — the script simply could not see its name from where CI stands.

Fixed with a second new option, `tools/pre-pr-check --branch <name>`, which CI fills from the pull request's head ref. The script still reads the branch from git everywhere else; CI is the one place that has to be told.

Worth noting how this surfaced: the workflow failed on the pull request that introduced it, which is the cheapest possible place for it to fail.

## Evidence

A workflow that is configured is not a workflow that runs, and this project has been wrong that way before. Two runs on this task's own pull request, against a phase branch:

- **`33214287797`** — the first, on `opened`. Every pull-request assertion passed, including `pass opened as a draft`; it failed on the detached-HEAD problem above.
- **`33214387232`** — after the fix, on `synchronize`. Green:

```
pr-check: 'ci/pr-check' into 'phase/10d-enforced-workflow' (event: synchronize)
pass base: phase/10d-enforced-workflow
pass closes issue #140
pass status fragment: docs/plan/10d-enforced-workflow/status/140-pr-check.md
pass draft state not checked on 'synchronize'; it is only meaningful at opening
pr-check: PASS
pre-pr-check: branch 'ci/pr-check' against 'origin/phase/10d-enforced-workflow'
pass branch name: ci/pr-check
...
pre-pr-check: PASS — 3 commit(s), 3 file(s) changed
```

The draft assertion is only exercised on `opened`, so its evidence is the first run's, not the second's — which is the honest reading of both.

## Open

Nothing in this task. It is the last of the phase.
