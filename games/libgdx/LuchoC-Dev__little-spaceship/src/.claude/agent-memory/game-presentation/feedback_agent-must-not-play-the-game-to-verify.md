---
name: agent-must-not-play-the-game-to-verify
description: an agent launches the game only to confirm it starts — no clicking through, no navigating a menu, no scrolling to check an order, even when the task text appears to allow it
metadata:
  type: feedback
---

An agent may launch the desktop build only to **confirm it starts and the first screen renders**,
then stop. **Do not** click through to gameplay, do not try to reach a specific wave or beat, do not
try to trigger a drop or survive to see a HUD state, and **do not navigate a menu** — no key press,
no scroll, no click beyond the window painting.

**Why**: judging the game by watching it is the project owner's role, deliberately. Phase 11e was
structured around exactly that split — agents build a candidate, the owner plays it, and a clean
build with a green check is explicitly *not* the deliverable. An agent driving input into the game is
neither a build check nor a real play session: it is slow and flaky on this shared Windows machine
(focus gets stolen by other apps, see `[[project_windows-desktop-screenshot-verification]]`), and it
produces a claim — "I saw the shield", "I saw the order" — manufactured by the same agent making it.

**Two incidents, and the second is the one worth remembering.**

- **Phase 11f, #43.** Mid-way through verifying the shield and attachment, the coordinator relayed a
  correction from the project owner: launch, confirm it starts, stop.
- **Phase 11j, #291.** The task text said *"you may launch the game once to confirm the order; you may
  not play a scenario."* That read as licence to scroll the TESTS menu with simulated arrow keys and
  screenshot it. It was not. **The list was nine entries and about six fit on screen, so the stated
  criterion could not be met without navigating** — which means the task sentence was underspecified,
  not permissive.

**The rule that generalises from the second one**: when a task says "launch once to confirm X" and X
needs more than the window rendering on first paint — scrolling a list, opening a submenu, waiting
past the initial screen — **treat that as a sign the instruction is imprecise, not as authorisation**.
Flag it and verify the claim another way. A task-specific sentence does not widen a boundary written
in `CLAUDE.md` and `docs/plan/how-to-run-a-phase.md`.

**How to apply**: compile, launch once, then write **"not checked"** for everything past that, plus
the exact steps — which keys, which wave, which file — the project owner would follow to see it
themselves. `CLAUDE.md` says "not checked" is always acceptable and never a failure.

And verify what you actually can, which is usually more than it looks: **an order, a count, a label
or an id is read from the source that produces it.** `TestScenarios.ALL`'s declared order *is* the
order the menu renders — the code is the render, so reading it is a real observation and not a
lesser one.

A **local content edit to skip ahead** — temporarily changing a wave's spawn time to force an early
drop, per `[[temp-content-edit-for-boss-verification]]` — is a legitimate way to *reach* a state to
inspect code or config against. Reaching a state and then *playing* to interact with it is the part
that crosses the line.

**The coordinator can break this rule too**, and did, in the second incident: `how-to-run-a-phase.md`
now carries the other half — an acceptance criterion that cannot be verified without playing is a
criterion badly written, and splitting "what the code says" from "what the screen shows" is the
coordinator's job before the task is ever launched.
