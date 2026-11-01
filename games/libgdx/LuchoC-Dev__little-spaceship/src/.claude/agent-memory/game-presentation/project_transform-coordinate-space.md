---
name: transform-coordinate-space
description: core.domain.Transform.x is playfield-local (0..208), not logical-resolution (0..480) -- game must add the playfield's left offset before drawing
metadata:
  type: project
---

`core`'s `Transform.x` is measured from the playfield's own left edge, in `[0, 208]`, not from the
480-wide logical resolution's origin. Confirmed two independent ways before trusting it: `MotionSystem`
clamps the player's x to `[margin, PLAYFIELD_WIDTH - margin]` (0..208 range), and `SpawnSystem`
computes a wave's anchor as `atX * PLAYFIELD_WIDTH` where `atX` is documented as a fraction of the
*playfield*, not the screen.

**Why this was easy to miss:** phase 03 built the renderer against an empty world (no player-spawn
capability existed in `core` yet), so drawing `x` unmodified compiled, ran, and drew nothing wrong —
there was nothing to draw. The bug only became visible once phase 04 gave `core` a reason to put an
entity anywhere but dead centre, and even then only by reasoning about the numbers, not by seeing a
sprite in the wrong place, since this session never had a display.

**How to apply:** any code in `game` that reads `Transform.x`/`Transform.y` directly through
`WorldView` and turns it into a screen position must add the playfield's left inset (`(logicalWidth
- playfieldWidth) / 2`, 136 at 480/208) to `x` before drawing. `y` needs no equivalent shift — the
playfield is the *full* logical height (270), only the width is inset and centred. `WorldRenderer`
in `game/adapter/render/` is where this correction lives today; a second renderer (HUD overlay,
minimap, anything else that positions by world coordinates) would need the same one.

See [[core-boundary-check]] for the sibling gotcha about accidentally importing `core.domain` while
reading this same data.
