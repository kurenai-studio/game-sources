---
name: worldrenderer-accept-ordering-decides-draw-order
description: How #236's shield shell got "behind ship-basic, in front of the aura" for free, and why a third PlayerStatus-boolean-driven overlay needed zero new state.
metadata:
  type: project
---

`WorldRenderer.accept` draws the invulnerability aura, then the ship sprite itself, in that literal
order within one method. For #236 (draw `fx-shield` behind the ship, in front of the aura), the only
change needed was inserting `drawShield(...)` between those two existing calls — no reordering, no
new boolean to remember "did the ship already draw this frame". When a spec states a draw order
relative to two things already drawn in the same method, check whether slotting the new call between
them already satisfies it before reaching for anything more elaborate.

This was the third instance of the same shape: `drawAttachment` (attachment flag), `drawAura`
(invulnerability source == POWERUP), now `drawShield` (`PlayerStatus.shieldActive()`). All three read
a boolean/enum already sitting on `playerStatus` — already crossing the `WorldView`/`PlayerStatus`
boundary for the HUD — and draw an extra region at the ship's live `x`/`y` from inside `accept`. No
core change was needed for #236 because `PlayerStatus.shieldActive()` already existed and
`HudRenderer` was already reading it for `icon-shield`; the pattern to check first, when a task asks
"draw X while some player state is true", is whether `PlayerStatus`/`WorldRenderer` already carries
that state before assuming a new port method is needed.

See also [[hud-icon-wiring-and-satellite-with-no-core-entity]] for the `drawAttachment` precedent
this generalises, and [[boss-ram-does-not-damage-player]] for the general reminder to check
`docs/planning/`/existing docs before assuming something is missing.
