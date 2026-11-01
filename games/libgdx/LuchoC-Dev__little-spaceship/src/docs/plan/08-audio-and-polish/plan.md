# Phase 08 — Audio and polish

**Lane:** art and code · **Owner:** `game-presentation` · **Depends on:** 06 · **Target:** day 6, continuing after the MVP

## Before you start

**Read, in this order:**

1. `docs/planning/02-mvp-functional-spec.md` — the audiovisual presentation section.
2. `docs/planning/07-references-and-asset-constraints.md` — licences apply to audio exactly as they do to art.

**Do not re-decide:** level music with a change on boss entry, and the three volume controls in options.

**Browser constraint:** audio needs a user gesture before it can play. The flow already provides one when the player presses Play, but confirm it on the real menu rather than assuming.

## Goal

What separates a game that works from a game that feels good. Audio, animation and game feel.

Part of this lands before the MVP; the rest is the bulk of the second milestone.

## Tasks

### Before the MVP

1. **Sound effects** for shooting, impacts, explosions, power-ups, the bomb and UI.
2. **Level music**, and the change on boss entry.
3. **Volume controls** wired to the options screen: master, music, effects.
4. **Browser audio unlock.** Browsers require a user gesture before audio plays. The flow already provides it — page loads, menu, the player presses Play — but it has to be confirmed on the real menu.
5. **Essential animations**: shooting, spawning, impact, explosion, death, pickup.

### After the MVP

6. Particles and screen shake on heavy impacts.
7. Hit feedback: flashes, brief pauses, knockback.
8. Screen transitions.
9. Dynamic music at difficulty peaks.
10. Game feel pass on the whole level, with playtesting.

## Acceptance criteria

- Every action in the flow has audible feedback.
- Music changes on boss entry and on returning to the menu.
- The three volume sliders work and persist between sessions.
- Audio starts without an error in the browser, verified on a real browser.
- Nothing important happens on screen without a visual cue.

## Risks

**Audio formats differ between backends.** What plays on desktop is not guaranteed to play in the browser. Verify formats on web early, not on release day.

**Polish has no natural end.** It is the phase that eats whatever time is left. Timebox it and prefer breadth — every action having feedback — over depth on any single effect.

## Licences

Same rule as art: CC0 preferred, CC-BY with documented attribution. Music and effects are licensed separately from sprites, and "free to use" is not the same as "free to redistribute". Record it when the asset enters.


## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, PR closing it, `reviewer` accepts against the criteria above, then update `status.md` and your agent memory.
