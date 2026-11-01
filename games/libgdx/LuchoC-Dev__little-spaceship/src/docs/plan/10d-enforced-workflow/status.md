# Phase 10d — Rules the tools enforce · status

**State:** done — merged into `dev` in [#152](https://github.com/LuchoC-Dev/little-spaceship/pull/152) and [#159](https://github.com/LuchoC-Dev/little-spaceship/pull/159)
**Updated:** 29/08/2026

This file holds the phase's `State:` line and its narrative, and the coordinator writes it — at the phase's opening and at its close.

**Per-task progress does not live here.** From task 1 onward it lives in `status/`, one file per task, written by whoever does that task on their own branch. That split is what this phase exists to build: in phase 11b every parallel agent edited one shared `status.md`, which produced a merge conflict, a forbidden force-push to escape it, and — from the two pull requests that never touched the file at all — two silent gaps in the record.

## Done

All six tasks, each recorded in its own file under `status/`. Read those for what each one did; this is what the phase amounts to.

**Five rules that were sentences are now mechanisms.**

| What used to depend on remembering | What enforces it now |
|---|---|
| edit the phase status without colliding with anyone | one file per task, so two tasks never write the same path |
| record your task at all | `pre-pr-check` fails a branch that does work and writes no fragment |
| write a well-formed commit subject | `tools/hooks/commit-msg` refuses a bad one as it is written |
| create your own worktree | the coordinator creates it; the agent is handed a path |
| target the right branch, close one issue, open as a draft | `pr-check` in CI, on every pull request |

**Two of the six changed shape while being built, and both times the issue was wrong rather than the work.**

- [#136](https://github.com/LuchoC-Dev/little-spaceship/issues/136) specified the fragment rule as `CODE_TOUCHED` — the `core|game|desktop|web|assets` condition that decides whether Gradle runs. Under it, **four of this phase's own six tasks would have been exempt**, since they change `tools/`, `.github/` and `.claude/`. The two conditions answer different questions: one asks "can this break the build", the other asks "is this work someone will want the record of". The rule became "a fragment unless the branch changes only `docs/`".
- [#137](https://github.com/LuchoC-Dev/little-spaceship/issues/137) and [#132](https://github.com/LuchoC-Dev/little-spaceship/issues/132) both asked for the subject check in `pre-commit`. **`pre-commit` receives no commit message and cannot do it** — only `commit-msg` does. Writing it where the issue said would have produced a hook that silently never fired, which is worse than none.

**Everything was verified by running it, not by reading it.** The fragment check was exercised in all three directions with scratch branches. The `commit-msg` hook was tested against three message files and then live, refusing a real commit. `pr-check` **failed on the pull request that introduced it** — `actions/checkout` leaves a detached HEAD, so `pre-pr-check` read the branch as `HEAD` and rejected it — which is the cheapest place a workflow can fail; run `33214287797` red, run `33214387232` green.

`pre-pr-check` also caught the missing executable bit on the new hook, the same failure that killed phase 09's first two CI runs.

## In progress

Nothing.

## Decisions taken while implementing

Record here anything decided that the plan did not specify, and why. If it changes how work is run, it also belongs in `docs/plan/how-to-run-a-phase.md` or in `CLAUDE.md`, which is the point of this phase.

## The `reviewer` pass, done after the phase was already on `dev`

The plan asked for one and the phase shipped without it. It was run afterwards, on the project owner's decision, with the brief the plan itself wrote: *"would an agent who has read only these documents do the right thing?"*

**Its answer was no, in one specific case, and it found the fifth and sixth gaps by building shapes nobody had lived through.**

- **[#154](https://github.com/LuchoC-Dev/little-spaceship/issues/154)** — `tools/hooks/commit-msg` exempted five commit-subject shapes and `tools/pre-pr-check` exempted one, so `git revert`'s own wording was welcomed at write time and rejected at the gate. Reverting is the **only** sanctioned way to undo here, since rebasing and force-pushing are forbidden, and no document warned of it. A fragment of this phase also claimed the two checks applied "the same rule" — false for four of five exemptions, written by testing one side and never the other.
- **[#155](https://github.com/LuchoC-Dev/little-spaceship/issues/155)** — neither check verified which phase's directory a fragment sat in, only its name, so one phase's work could be recorded in another's status and the phase it belonged to would be silently short.

**Fixing them produced two more instances of the same fault**, and they are the most useful thing this phase learned:

- the fragment check counted *changed* fragments as well as added ones, so correcting the false document was itself forbidden by the check;
- and then `pr-check.yml` failed the pull request that fixed the first drift, because `pre-pr-check` had been taught the fix and it had not — **one rule, two implementations, drifting inside the pull request whose subject was one rule in two implementations drifting.**

That is why the phase now ships three shared scripts — `tools/commit-subject-ok`, `tools/status-fragments` and its `--misplaced` mode — rather than matching logic kept in agreement by care. **If two things must agree, do not write it twice.** Six of the eight faults in this phase were one rule stated from one point of view; the other two were one rule stated twice.

## Notes for whoever comes next

**The gap between the two checks is real and deliberate.** `pre-pr-check` runs before the pull request exists — that is its purpose — so it cannot see the issue, and it exempts any branch whose diff is entirely under `docs/`. That exemption is meant for the coordinator's bookkeeping, but the script cannot tell bookkeeping from documentation work that closes an issue. Task 4 went through that gap in this very phase. **`pr-check` is what closes it**, because it can see the issue: closes one → a fragment named for it; closes none → the diff must be documentation only.

**`ci.yml` was deliberately not touched.** A workflow firing on both `push` and `pull_request` for one commit doubles the Gradle minutes. The split is: `ci.yml` on push, compiling, testing and running the **real** TeaVM build; `pr-check` on `pull_request`, asserting facts about the pull request and running `pre-pr-check --no-build`. If you ever make `pr-check` build, remove the push trigger first.

**The limit on `pr-check` is the project owner's and it is written in the workflow's own header**: it verifies only facts checkable without reading prose. Every future annoyance will look like something the script could catch. If verifying it requires reading English and forming a view, it belongs to `reviewer`.

**The `reviewer` pass was done after the fact** and is recorded above; what follows was written before it and is left as the dated record it is. **What this phase did not do at the time:** a `reviewer` pass. The plan's risk section argued for one, on the grounds that the coordinator wrote the prompts these rules exist to fix and is therefore the worst person to notice a rule that only makes sense to someone who already has the context. The brief it suggested is still the right one — *"would an agent who has read only these documents do the right thing?"* — and 11c is the first phase that will answer it in practice.
