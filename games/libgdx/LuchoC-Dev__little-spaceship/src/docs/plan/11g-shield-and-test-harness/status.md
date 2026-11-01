# Phase 11g — The shield drop, and a test harness for `game` · status

**State:** **done and merged into `dev`** in [#242](https://github.com/LuchoC-Dev/little-spaceship/pull/242), with the project owner's direct approval on 02/09/2026. Three tasks, five pull requests, and both play-verifiable results confirmed by the project owner.
**Updated:** 02/09/2026

This file holds the phase's `State:` line and its narrative, and the coordinator writes it — at the phase's opening and at its close.

**Per-task progress does not live here.** It lives in `status/`, one file per task, written by whoever did that task on its own branch.

## Done

| Task | Issue | What | PR |
|---|---|---|---|
| 1 | [#230](https://github.com/LuchoC-Dev/little-spaceship/issues/230) | A `shield` drop in level 1, at 37.0 s | [#234](https://github.com/LuchoC-Dev/little-spaceship/pull/234) |
| 2 | [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19), the unblocked half | A test harness for `game` | [#235](https://github.com/LuchoC-Dev/little-spaceship/pull/235) |
| 3 | [#236](https://github.com/LuchoC-Dev/little-spaceship/issues/236) | The shield drawn on the ship | [#237](https://github.com/LuchoC-Dev/little-spaceship/pull/237) art, [#239](https://github.com/LuchoC-Dev/little-spaceship/pull/239) wiring |

Plus the opening [#233](https://github.com/LuchoC-Dev/little-spaceship/pull/233) and [#240](https://github.com/LuchoC-Dev/little-spaceship/pull/240), a one-line correction.

**Task 3 was not planned.** It came out of the play session for task 1: the project owner collected the new shield, saw `icon-shield` light in the HUD, and found **nothing on the ship**. A defect found while the phase runs gets an issue like any other task.

**Verified by the project owner**, on 01/09 and again on 02/09: the shield drop falls where intended and the placement is right; the reward cadence still reads as it should; and the shell appears on pickup, follows the ship, and vanishes on the hit.

## The phase's own result

**`game` can be tested at all, and it turned out nothing was ever in the way but a decision.**

`game` had **no tests**. `core` has over three hundred. [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19) had been open since phase 03, and the blocker was never priority — it was that almost everything in `game` touches libGDX and nobody had decided how to stand in for it.

The harness is `game/src/test/java/.../testsupport/FakeInput.java` and `FakeGraphics.java`: JDK dynamic proxies over `com.badlogic.gdx.Input`/`Graphics`. **It added no dependency and changed no `build.gradle`** — the test source set already worked and was simply empty. The one real test drives `InputAdapter.sample()` and pins the additive-devices rule: keyboard alone reaches `playerSpeed()`, and an opposing keyboard hold plus a mouse delta cancel to `(0,0)`.

**And phase 03 had already solved it.** Two throwaway programs verified input summing with exactly this technique; `docs/plan/03-first-playable/status.md` transcribes their output. **They were never committed.** The technique was never the defect — the defect was that the evidence could not be reproduced by anyone, and it cost this project three weeks of an untestable module.

**The mutation was reproduced twice.** The author changed `140f` to `999f`, saw red, and reverted. The coordinator did it again on the merged tree: `2 tests completed, 1 failed`, then green. A test that cannot fail proves nothing, and this one demonstrably can.

## The other result: two documents were wrong, and only one was found on purpose

**The one that was looked for.** [#230](https://github.com/LuchoC-Dev/little-spaceship/issues/230) existed because [#43](https://github.com/LuchoC-Dev/little-spaceship/issues/43) wired `icon-shield` from art already sitting unreferenced in the atlas, and level 1 then turned out to carry no `shield` drop at all. The icon was correct and unreachable — and nobody could have known until it was wired.

**The one that was not.** Designing the ring meant deciding how it stays distinct from the invulnerability aura. `visual-designer` went and read `game/adapter/render/WorldRenderer.java` instead of trusting `docs/design/04-hud-layout.md`, and found the document calls that aura a *"`C1` aura ring, 21x21, 2-frame loop"* against a `drawAura` that draws a **static square of four 1-px lines**. Wrong on shape and wrong on animation. Filed as [#238](https://github.com/LuchoC-Dev/little-spaceship/issues/238).

That nearly cost something: designing against an animated ring would have produced a different answer than designing against a static square. It came out right only because the agent did not believe the document. `CLAUDE.md` calls `04-hud-layout.md` and `HudRenderer` *"the most accurate document/code pair in the repository"* — and the pair holds for the plate. **That sentence was about `WorldRenderer`, the other side of the same document, which was never held to the standard.**

## Decisions taken while implementing

Both recorded in `docs/planning/08-decisions-and-open-items.md`, dated 02/09/2026.

- **Level 1 carries a shield at 37.0 s.** Placed *before* the beats it defends against rather than beside them, into the level's longest reward drought and at its first density spike. Three alternatives refused with reasons — including one that is mechanically impossible, since `LifetimeSystem` strips `Drop` from an escaping enemy and beat 6's `enemy-rush` escapes.
- **An active shield is drawn on the ship**, which overrules `04-hud-layout.md` as it stood. Green, because cyan was already spent twice near the hull and a cyan shell reads as *the ship glowing* rather than as *a thing around the ship*.

## What is open

- [#238](https://github.com/LuchoC-Dev/little-spaceship/issues/238) — the aura's description. Deliberately not folded into [#236](https://github.com/LuchoC-Dev/little-spaceship/issues/236), which scoped the invulnerability states away.
- [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19) **stays open.** This phase answered the harness half. What to assert about `JsonContentSource`'s error messages depends on the file format and stays scheduled to the 12 group, per D5 of 11a.
- **Not checked:** the web target. Everything here was verified on desktop, and `CLAUDE.md` records that headless Chrome cannot validate the web runtime.

## Notes for whoever comes next

**One test is a harness, not a suite.** `game` now has two passing tests where it had none, and the value is that the *next* test costs nothing to write. `docs/plan/11g-shield-and-test-harness/status/19-game-test-harness.md` says what the harness cannot do — the proxies answer only the eight methods they implement, and the technique is unverified against TeaVM's own `Input`/`Graphics`, since these tests run on the JVM only.

**The atlas is generated.** `assets/atlas/sprites.png` and `.atlas` come from `docs/design/mockups/src/01-sprites.js` through `docs/design/atlas/build-atlas.js`. Sprites are authored as ASCII pixel art against `00-palette.js`; **never hand-edit the PNG**. Adding `fx-shield` grew the page from 128x163 to 132x163 and moved existing regions, which is why one new sprite produced a 77-line `.atlas` diff.

**Two coordinator errors are recorded rather than corrected quietly.** The phase's opening commit landed directly on the phase branch, because `git worktree add -b` did not create the branch and the worktree came up on the phase itself — caught only because the `pre-pr-check` result was read instead of chained past. And [#237](https://github.com/LuchoC-Dev/little-spaceship/pull/237) was merged with no `reviewer` pass; it was audited retrospectively afterwards, alongside [#239](https://github.com/LuchoC-Dev/little-spaceship/pull/239), and nothing was found.
