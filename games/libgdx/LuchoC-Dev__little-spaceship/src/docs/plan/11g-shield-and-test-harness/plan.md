# Phase 11g — The shield drop, and a test harness for `game`

**Lane:** content + tests · **Owner:** `level-designer` for the drop, `test-engineer` with `game-presentation` for the harness · **Depends on:** 11e (level 1 as it now stands) and 11f (the shield icon exists and is wired)

**Not in `post-mvp-roadmap.md`.** This phase was opened on 01/09/2026 by the project owner, from two things the 11 group left behind: one it could not have known about until 11f wired the icon, and one that has been open since phase 03.

## Before you start

**Read, in this order:**

1. Your task's issue in full — [#230](https://github.com/LuchoC-Dev/little-spaceship/issues/230) or [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19).
2. `docs/plan/11f-web-defects/status.md`, "What is open", and `docs/plan/11e-level-one-redesigned/status.md`.
3. For the harness: D5 in `docs/plan/11a-rule-asserting-tests/status.md`, which is the decision this phase is executing half of, and `docs/plan/03-first-playable/status.md`, which transcribes the output of two programs nobody can run.
4. `CLAUDE.md`, in particular **"Running the game is not playing it"** in [`../how-to-run-a-phase.md`](../how-to-run-a-phase.md).
5. Your agent memory.

## Goal

**A shield can be picked up in level 1, and `game` can be tested at all.**

## Tasks

1. **[#230](https://github.com/LuchoC-Dev/little-spaceship/issues/230) — put a `shield` drop in level 1.** `level-designer`, on `assets/data/`. 11f wired `icon-shield` into `HudRenderer` from art that was already in the atlas; level 1 then turned out to contain no `shield` drop at all, only `weapon-upgrade` ×3, `extra-life`, `attachment` and `bomb-recharge`. **The icon is correct and unreachable.**

   **Where it goes is a design decision and it must be argued, not picked for convenience.** Level 1 is twelve waves over fourteen beats in 134.5 s, and the project owner signed off its balance on 01/09/2026 after two play sessions. A fifth drop changes that. Justify the placement against the intensity curve in `docs/levels/level-01.md`, and say what it costs.

   **A shield is worth having before it is needed, not as a prize beside the attachment.** That is a starting opinion, not a decision — argue with it if the curve says otherwise.

2. **[#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19), the half that was never blocked — a way to test `game` at all.** `test-engineer`, with `game-presentation` where it crosses into that module.

   `game` has **no tests**. `core` has over three hundred. The blocker has never been priority: it is that almost everything in `game` touches libGDX, and nobody has decided how to stand in for it. #19's own text calls this *"the question to answer first"*.

   **This half does not depend on the file format**, which is what `reviewer` established when it was asked to argue with 11a's D5 and did. The other half — what to assert about `JsonContentSource`'s error messages — stays scheduled to the 12 group and is **out of scope here**.

   **The shape of the answer may already exist and nobody can run it.** Phase 03 verified input summing and a non-empty world with two throwaway programs that used JDK dynamic proxies for `Gdx.input`/`Gdx.graphics`. `docs/plan/03-first-playable/status.md` transcribes their output. **They were never committed.** That is the failure this task exists to end: evidence that cannot be reproduced is not evidence.

## Acceptance criteria

- **A shield is reachable in level 1**, and the project owner has played it: the drop falls, it is collectable, and `icon-shield` lights.
- The placement's reasoning is written down, and if it changes level 1's balance, that is recorded in `docs/planning/08-decisions-and-open-items.md` — level 1 was signed off on 01/09 and this reopens it.
- **`game` has a test suite that runs under `./gradlew build`**, with at least one real test in it. One honest test that proves the harness works beats a suite of assertions about nothing.
- **The harness does not drag LWJGL into the suite**, and nothing in it reads the clock, spawns a thread, or breaks the TeaVM constraints — the same rules `core` lives under, because a test that cannot run everywhere is a test that stops running.
- **It is committed and reproducible.** No throwaway programs, no transcribed output. That is the whole point.
- The verdict on the shield's placement comes from **playing**, per the rule decided on 22/08 and again on 25/08.

## What is out of scope

- **Assertions about `JsonContentSource`'s error messages.** The 12 group, per D5. Building the harness is not an invitation to use it on the loader yet.
- **Levels 2 and 3.** Phase 12.
- **Rebalancing anything the shield drop does not touch.** The project owner approved level 1 on 01/09; this phase adds one pickup, it does not reopen the level.
- **New art.** `icon-shield` and `pickup-shield` already exist in `assets/atlas/sprites.png`.
- The rest of `game`'s untested surface. One harness and one real test; covering `game` is not this phase.

## Risks

**Rebalancing level 1 by accident.** The owner signed it off hours before this phase opened, twice from play. A fifth drop in 134 seconds is a real change and it is the only one this phase is allowed to make.

**Building a harness nobody uses.** A proxy layer with no test against it is scaffolding, not infrastructure. The acceptance criterion asks for one real test for exactly this reason.

**Rebuilding phase 03's throwaway programs and throwing them away again.** They worked. The defect was never the technique, it was that they were not committed.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, a pull request against `phase/11g-shield-and-test-harness`, then a status fragment before review.
