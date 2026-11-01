# Phase 11f — The four web defects

**Lane:** presentation · **Owner:** `game-presentation` · **Depends on:** nothing · **Runs in parallel with the rest of the group, from day one**

## Before you start

**Read, in this order:**

1. [`../post-mvp-roadmap.md`](../post-mvp-roadmap.md), "What playing the web build found" and "The four web defects".
2. `docs/STATUS.md`, "Post-MVP backlog, from real play on 25/08".
3. `CLAUDE.md`, "Web target pitfalls". Every one of them cost hours during the spike.
4. Your agent memory in `.claude/agent-memory/game-presentation/`.

## Goal

**The four defects a stranger hits in the first minute of the deployed build are fixed.**

## Why this runs in parallel

It touches `game/`, `desktop/` and `web/` and nothing in `core/`. The wave system, the movement shapes
and the balance pass all live in `core/` and `assets/data/`, so the two lanes cannot collide — which is
the same reason the art and code lanes ran in parallel through the MVP. Use a worktree, branched from
this phase's branch, as `how-to-run-a-phase.md` describes.

It also has no dependency on 11a, and that is deliberate: 11a is about the rules in `core`, and `game`
has no test suite at all ([#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19)), which is
this phase's first question rather than a reason to wait.

## Tasks

1. **[#40](https://github.com/LuchoC-Dev/little-spaceship/issues/40) — QUIT does nothing on the web
   target.** `MenuScreen.java:30` wires it to `Gdx.app::exit`, which closes the window on desktop and
   can do nothing in a browser: JavaScript may not close a tab it did not open. **The fix is a decision
   before it is code** — hide it on web, give it a different meaning there, or accept it — and
   `02-mvp-functional-spec.md` asks for Play/Options/Quit, written for a desktop game. It is the first
   dead control a stranger meets, so "accept it" needs a reason if it wins.
2. **[#41](https://github.com/LuchoC-Dev/little-spaceship/issues/41) — losing pointer lock breaks
   mouse control until the page is refocused.** Worth singling out, and the roadmap does: phase 09's
   task 4 was "verify pointer capture", it was never actually verified, and this is the defect that
   would have caught. Everything else in that phase was checked against reality; this one criterion
   was assumed.
3. **[#42](https://github.com/LuchoC-Dev/little-spaceship/issues/42) — no in-game options.** Volume
   cannot be changed while playing. `BaseUiScreen` and `GameSkin` are what the seven existing screens
   are built on.
4. **[#43](https://github.com/LuchoC-Dev/little-spaceship/issues/43) — the shield and the attachment
   are invisible.** No sprite, no animation. Note before drawing anything new: `module-satellite`,
   `ship-bank`, `ship-tilt`, `ship-hit`, the thrust and muzzle effects and five `icon-*` glyphs are
   **already in `assets/atlas/sprites.png` and referenced by nothing** — art waiting for a system. Check
   what exists before asking `visual-designer` for more.
5. **Decide #19, or execute the decision 11a made about it.** `game` has no tests, and the loader's
   error paths are what they would cover. 11a owns the decision of where it goes; if it landed here,
   this is where it gets done.

## Two things in the backlog that are adjacent and are *not* this phase

Stated so they are not picked up by accident, and not lost either:

- **The shooting sound glitches under sustained fire**, most likely `Sound` instance exhaustion — every
  shot starts a new one and nothing bounds them. Not diagnosed. It is a real defect and it has no
  issue; open one rather than fixing it in passing.
- **The download is 2.5 MB and 1.3 MB of it is two uncompressed music WAVs.** Encoding to OGG is the
  single largest load-time win available and libGDX plays OGG on both targets. Measured on 25/08, not
  done because the MVP was frozen. Also worth an issue.

Neither is in this phase's scope unless the project owner adds it.

## Acceptance criteria

- Each of #40, #41, #42 and #43 is closed, and each closure cites **the deployed build**, not a local
  desktop run. A screenshot, a URL, or the steps that used to reproduce it and now do not.
- #41 in particular is verified by losing pointer lock in a real browser and regaining control. Phase
  09 assumed this criterion; this phase does not get to.
- #40's outcome includes the decision and its reason, not only the code.
- `core` is untouched. Nothing in this phase imports from `core.domain` beyond
  `core.domain.event`/`core.port`, which is the existing boundary — `docs/STATUS.md` records why the
  event package crossing is not a violation, and the mechanical grep in your own memory will flag it.
- The web build compiles and the game still runs in a real browser. **Headless Chrome cannot validate
  the web runtime** — it fails under SwiftShader even when a real browser works, so CI proves the
  build compiles and a human proves it runs.
- `assets/startup-logo.png` still exists. Without it the app crashes when preloading finishes, with an
  error that never mentions the logo.

## What is out of scope

- **Anything in `core/`.** Game rules are `core-domain`'s and they are being changed by three other
  phases at the same time as this one.
- The audio glitch and the OGG encoding, per the section above.
- New art. If a fix needs a sprite that does not exist, that is `visual-designer`'s and it is a
  conversation, not a decision to take alone.
- Safari. Chrome and Firefox are verified; Edge was dropped by the project owner; Safari remains
  unverified and stays that way unless the owner says otherwise.

## Risks

**Assuming a fix instead of verifying it**, which is precisely how #41 got shipped. The evidence rule
in `CLAUDE.md` applies with full force here: a claim about a system cites an observation of that
system — the command and what it printed, or the URL and what happened.

**Colliding with the other lane.** Both lanes touch `assets/`: this one the atlas, the other
`assets/data/`. Different directories, but the same tree — use a worktree and keep the pull requests
narrow.

**Fixing #43 by drawing rather than by wiring.** Four times in two days, art a phase called delivered
existed only under `docs/design/` with nothing in `assets/` and no code loading it. The reverse case is
live here: the art exists and nothing loads it.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, a pull
request against `phase/11f-web-defects`, then `status.md` before review.
