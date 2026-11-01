# Phase 11f — The four web defects · status

**State:** **done and merged into `dev`** in [#232](https://github.com/LuchoC-Dev/little-spaceship/pull/232), with the project owner's direct approval on 01/09/2026. Five tasks, five pull requests, and all four defects verified by the project owner in a real browser and on the desktop build. **This completed the 11 group.**
**Updated:** 01/09/2026

This file holds the phase's `State:` line and its narrative, and the coordinator writes it — at the phase's opening and at its close.

**Per-task progress does not live here.** It lives in `status/`, one file per task, written by whoever did that task on its own branch. Read those for what each one did; this is what the phase amounts to.

## Done

**It is the last phase of the 11 group.** Every one of the five tasks already had an issue: these are defects found by playing the deployed build on 25/08/2026, not tasks the plan invented.

| Task | Issue | What | PR |
|---|---|---|---|
| 1 | [#40](https://github.com/LuchoC-Dev/little-spaceship/issues/40) | QUIT does nothing on the web target | [#228](https://github.com/LuchoC-Dev/little-spaceship/pull/228) |
| 2 | [#41](https://github.com/LuchoC-Dev/little-spaceship/issues/41) | Losing pointer lock breaks mouse control | [#221](https://github.com/LuchoC-Dev/little-spaceship/pull/221) |
| 3 | [#42](https://github.com/LuchoC-Dev/little-spaceship/issues/42) | No in-game options | [#227](https://github.com/LuchoC-Dev/little-spaceship/pull/227) |
| 4 | [#43](https://github.com/LuchoC-Dev/little-spaceship/issues/43) | The shield and the attachment are invisible | [#224](https://github.com/LuchoC-Dev/little-spaceship/pull/224) |
| 5 | [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19) | `game` has no test suite | [#229](https://github.com/LuchoC-Dev/little-spaceship/pull/229) — no code owed |

Plus the opening [#220](https://github.com/LuchoC-Dev/little-spaceship/pull/220), [#222](https://github.com/LuchoC-Dev/little-spaceship/pull/222) (an agent may launch the game, never play it) and [#226](https://github.com/LuchoC-Dev/little-spaceship/pull/226) (carrying 11e's merged record so that only one pull request reaches `dev`).

**Verified by the project owner on 01/09/2026**, in a real browser and on the desktop build: the pointer-lock recovery and that Escape still pauses as before; the farewell screen and its way back; the in-game options panel and that re-pausing opens on RESUME; QUIT still exiting on desktop; and the attachment appearing at beat 11. That is the closure evidence this phase's criteria require, and no agent could have supplied it.

## The phase's own result

**Twice, reading a jar settled something no run could.**

Both of the phase's hardest questions were about how libGDX behaves *under TeaVM*, and both were answered by unzipping `backend-web-1.6.1-sources.jar` from the Gradle cache — which ships alongside the binary and which nobody here had opened before.

- **`isCursorCatched()`** turned out to be a live DOM read of `document.pointerLockElement`, not a cached flag (`WebInput.java:785-786`, `1018-1026`). That confirmed the fix's mechanism — and then exposed a defect in it.
- **`Gdx.app.getType()`** returns `ApplicationType.WebGL` as a constant (`WebApplication.java:440-441`), so [#40](https://github.com/LuchoC-Dev/little-spaceship/issues/40)'s platform branch is reached rather than merely compiling.

**The defect that reading found, and running could not have.** [#221](https://github.com/LuchoC-Dev/little-spaceship/pull/221)'s first version tested for a lost pointer lock in the same call that requested it. `setCursorCatchedJSNI` calls `element.requestPointerLock()`, which browsers grant **asynchronously**, so on the web target the click that engaged the mouse would have paused the game — and the next click would have done it again, forever. **On desktop LWJGL3 applies the catch synchronously, so a local run showed it working perfectly.** `reviewer` raised it as a suspicion it could not confirm; the coordinator confirmed it from the source; the fix became a `pointerCaptureConfirmed` latch that arms only once the grant has been observed, rather than a fixed frame count that would only have relocated the race.

**A design decision that came from refusing to guess.** [#42](https://github.com/LuchoC-Dev/little-spaceship/issues/42) did not open the existing `OptionsScreen` from the pause panel, because `game/LittleSpaceshipGame.java`'s `setScreen` disposes the outgoing screen immediately — doing so would have torn down the whole `Simulation` to move a volume slider. The pause panel swaps its own children in place instead. `reviewer` was asked to verify that claim rather than accept it, and it holds.

**And one exclusion worth more than an inclusion.** [#42](https://github.com/LuchoC-Dev/little-spaceship/issues/42) left the mouse toggle out of the in-game panel on the grounds that changing it mid-run interacts with live pointer-lock state — [#41](https://github.com/LuchoC-Dev/little-spaceship/issues/41)'s own subject — and could not be honestly verified within the task. `reviewer` checked and found the reasoning *understated*: `managePointerCapture` releases capture only on Escape, never on `mouseEnabled` going false, so a live toggle-off would have left the cursor captured with no way out.

## Decisions taken while implementing

- **On the web target, QUIT keeps its slot and means something else**: it opens `game/screen/FarewellScreen.java`, with a way back to the menu. On desktop it still exits. Decided by the project owner, who refused two alternatives — hiding the entry on web, and repurposing the slot as a fullscreen toggle. The screen carries **no score, deliberately**: QUIT lives on the main menu where no run is in progress, and `game/GameSettings.java` persists only volumes and the mouse toggle. Recorded in `docs/planning/08-decisions-and-open-items.md` as "Menu and screens, 01/09/2026".
- **The pause panel gains OPTIONS**, opening an inline panel rather than a screen, with volume only. Recorded there as "In-game options, 01/09/2026".
- **`docs/planning/02-mvp-functional-spec.md` is corrected for both**, struck through and dated rather than silently rewritten. It was written for a desktop game and two of its sentences stopped being true today: "Quit", and "No full pause menu".
- **An agent may launch the game only to confirm it starts, never to play it.** Decided by the project owner mid-phase, when an agent began driving the game to see the shield for itself. The rule and its reasoning are in [`../how-to-run-a-phase.md`](../how-to-run-a-phase.md), "Running the game is not playing it"; `CLAUDE.md` carries a pointer rather than a second copy.

## What is open

**Three issues this phase opened and did not close**, none of them blocking:

- [#225](https://github.com/LuchoC-Dev/little-spaceship/issues/225) — a **denied** pointer lock leaves the player stuck with no way to re-request it. The other branch of [#41](https://github.com/LuchoC-Dev/little-spaceship/issues/41): not the lock revoked after being granted, but the grant that never arrives. **Pre-existing on `dev`**, verified against `git show dev:.../InputAdapter.java`, so not a regression from [#221](https://github.com/LuchoC-Dev/little-spaceship/pull/221).
- [#230](https://github.com/LuchoC-Dev/little-spaceship/issues/230) — the shield HUD icon is wired and **unreachable**: level 1 contains no `shield` drop at all, only `weapon-upgrade` ×3, `extra-life`, `attachment` and `bomb-recharge`. `game-presentation` stopped at the module boundary rather than editing a level to make its own work visible, which is correct. Whether level 1 should have one is a design question for the project owner — level 1 was signed off on 01/09 after two play sessions.
- [#223](https://github.com/LuchoC-Dev/little-spaceship/issues/223) — `tools/pre-pr-check` treats `CLAUDE.md` as code, so a coordinator documentation branch that touches it cannot pass. Found the hard way: the check went red, the failure was missed through a badly chained shell command, and [#222](https://github.com/LuchoC-Dev/little-spaceship/pull/222) was merged anyway. Reported rather than quietly corrected.

**And two carried in from earlier**, both named by the plan and given issues at this phase's opening rather than being fixed in passing: [#218](https://github.com/LuchoC-Dev/little-spaceship/issues/218), the shooting sound glitch — hypothesis only, **not diagnosed** — and [#219](https://github.com/LuchoC-Dev/little-spaceship/issues/219), the 2.5 MB download of which 1.3 MB is two uncompressed WAVs, measured on 25/08.

**[#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19) stays open on purpose.** Task 5 is discharged; the issue is not. 11a decided on 27/08 that it goes to the 12 group, and `reviewer` split it: what to assert about the loader's error messages depends on a format 11b was rewriting, but **how to unit-test anything depending on `FileHandle` without dragging LWJGL into the suite was never blocked** and is still unanswered. That half has been quietly costing this project since phase 03, whose two verification programs used JDK dynamic proxies and **were never committed** — the evidence exists in `docs/plan/03-first-playable/status.md` and nobody can reproduce it.

**Unresolved and needing the project owner:** D5 ends with *"Put to the project owner, because it adds scope to a group that is not planned yet."* The 12 group is not planned, so nobody with the authority to add scope to it has accepted that split.

## Notes for whoever comes next

**`gdx-teavm` ships its sources and they are in the Gradle cache.** Twice in one phase that settled a question a local run could not, and once it exposed a defect that desktop was structurally incapable of showing. When the question is "what does libGDX actually do on the web target", the answer is a `unzip` away and it is cheaper than guessing.

**`assets/startup-logo.png` still exists**, 12214 bytes, confirmed on the merged tree. Without it the app crashes when preloading finishes, with an error that never mentions the logo.

**Safari remains unverified**, deliberately. Chrome and Firefox are verified, Edge was dropped by the project owner, and Safari stays out of scope unless the owner says otherwise.
