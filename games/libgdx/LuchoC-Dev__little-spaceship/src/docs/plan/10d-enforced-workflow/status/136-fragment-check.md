# 136 — pre-pr-check requires a status fragment

**Task 2** · closes [#136](https://github.com/LuchoC-Dev/little-spaceship/issues/136) · branch `build/status-fragment-check`

## What was done

`tools/pre-pr-check` gained check 8: a branch that does work must add **exactly one** file matching `docs/plan/<phase>/status/<name>.md`. Zero fails, two or more fails and names them, one passes and prints the path.

## The decision the issue did not specify

The issue said "when the diff touches `core/`, `game/`, `desktop/`, `web/` or `assets/`" — reusing `CODE_TOUCHED`, the condition that decides whether to run `./gradlew build`. **That was wrong and it was caught by writing the check, not by reading the issue.**

Under that condition, tasks 3 to 6 of this very phase — which change `tools/`, `.github/` and `.claude/agents/` — would each have been exempt from recording anything. A phase about making work traceable would have left four of its six tasks untraced.

The two conditions answer different questions:

- `CODE_TOUCHED` asks **"can this break Gradle?"** — and `tools/` cannot.
- The fragment check asks **"is this work someone will want the record of?"** — and a change to `tools/`, to a workflow, or to an agent definition is exactly that.

So the rule is now: **a fragment is required unless the branch changes only `docs/`.** That exemption is the coordinator's bookkeeping — opening a phase, closing it, correcting a document — which is the same category [#137](https://github.com/LuchoC-Dev/little-spaceship/issues/137) names as closing no issue.

## Verified in all three directions, by running it

Not by reading it. A scratch branch was built for each case and thrown away afterwards.

| Case | Result |
|---|---|
| touches `assets/`, no fragment | `FAIL this branch does work and records nothing in the phase status` |
| same branch, fragment added | `pass status fragment: docs/plan/10d-enforced-workflow/status/999-scratch.md` |
| changes only `docs/`, no fragment | `pass docs-only branch, so no status fragment is required` |

The third case needed care and got it wrong twice first: a scratch branch cut from `build/status-fragment-check` carries that branch's own `tools/` change in its diff against the phase branch, so it is not docs-only however it looks. It was finally run from a copy of the script outside the repository, against a branch cut from the phase branch itself, so the working tree stayed clean and the diff contained only the documentation change.

## What this check deliberately does not do

It checks **presence, not the name**. The convention is `<issue>-<slug>.md`, but this script runs *before* the pull request exists — that is its purpose — so it cannot know which issue the pull request will close. Verifying the name against the issue belongs to [#140](https://github.com/LuchoC-Dev/little-spaceship/issues/140), which runs on the pull request and can see it.

## Open

Nothing here. Note for [#140](https://github.com/LuchoC-Dev/little-spaceship/issues/140): it inherits the same exemption, and the two must agree on what "docs-only" means or a branch will pass one and fail the other.
