# Phase 09 — Low-risk UX tidy-ups

This follow-up phase is a grab-bag of small, low-risk improvements that make Phase 08 playtesting smoother without changing core rules.

## What shipped

### DebugText readability + ergonomics

- DebugText left column now starts at x=0 (reclaims unused pixels).
- `Scenario:` label is shortened to `Scn:` to fit longer names.
- Scenario descriptions are word-wrapped so they never run off-screen.
- After pressing `Next` (scenario switch), the cursor stays on `Next` (so you can quickly iterate).
- Anchor display is now safe (no more `uidundefined`).

### Sly Deal playtest quality-of-life

- `moveStress` scenario gives the opponent multiple stealable targets so Sly targeting cycles more meaningfully.
- Hold‑A on Sly with **no targets** enters hold‑A **hold-chain** targeting starting at **Bank** (so you can still Bank the card quickly).

