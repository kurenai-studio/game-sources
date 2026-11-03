# Game 03: Çini Ustası (Iznik tile puzzle)

Same block structure as games 01 and 02 (World, Life, Game rules, Interaction, HUD, Extras, Performance, Self-test).
Written by the orchestrator; the game itself is built by a different model each time (see the series table).

```text
Build a single-file browser game (one index.html with inline CSS and JS) using Three.js r170 loaded
as an ES module from https://cdn.jsdelivr.net/npm/three@0.170.0/ (import map; addons from examples/jsm
if needed). A 3D puzzle game called "Çini Ustası" (Turkish for "tile master"). Do not ask questions,
build it end to end.

WORLD: a warm, low-poly tile workshop seen from above at a slight angle, built entirely in code, no
external models, images or fonts beyond one Google Font. A wooden work table with the puzzle board in
the middle, brushes, paint pots (cobalt blue, turquoise, coral red, emerald green), a small kiln glowing
in the corner, shelves with finished plates and vases, a window with soft afternoon light and floating
dust motes. Every tile is a slightly bevelled square with its motif drawn procedurally (canvas textures
generated at runtime or geometry): tulips, carnations, saz leaves, rumi scrolls and border bands in the
classic Iznik palette on a white glaze. Clean, calm, handcrafted look.

LIFE: when a board is solved, the motifs connect across the whole board, the tiles glaze with a shine
sweep, the finished panel slides into the kiln, fires with a glow, and comes out as a framed piece that
is added to the wall of finished work (the player's collection). Dust motes drift, the kiln flickers,
a cat occasionally walks along the shelf.

GAME RULES: edge-matching puzzle. Each tile edge carries a motif half (shape + colour). A board is solved
when every shared edge matches and the border edges match the frame. 30 levels in 3 chapters that each
add one mechanic: chapter 1 rotate tiles in place (3x3 to 5x5), chapter 2 also swap any two tiles,
chapter 3 adds fixed tiles, double-sided tiles you can flip, and 6x6 boards. Every level must be
solvable and have one clean solution pattern (generate the solved board first, then scramble). Move
counter, undo, a limited hint that fixes one tile, 1-3 stars by moves against par. Levels unlock in
order; a daily random board after chapter 1. Progress and best stars saved in localStorage.

INTERACTION: click or tap a tile to rotate it 90° (animated), drag a tile onto another to swap them,
right-click or long-press to flip a double-sided tile. Matching edges glow softly so progress is
readable. Scroll or pinch to zoom a little, drag on the table to tilt the camera slightly (clamped).
Keyboard: Z undo, H hint, R restart, Esc menu.

HUD: frosted glass panels over the 3D view: top bar (logo, chapter and level, moves vs par, stars, hint
count, sound, language), level select with stars per level, the collection wall as a gallery, a short
how-to on the first level of each chapter, level-complete card, toasts. Turkish by default with an
English toggle.

EXTRAS: calm generated music (soft oud-like plucks or a gentle drone with Web Audio) and synthesised
sound effects (tile click, rotate swish, match chime, kiln whoosh, completion fanfare), separate music
and sound toggles; works on mobile with touch.

PERFORMANCE (must run at 60 fps on an Intel UHD 620 laptop iGPU): renderer pixel ratio capped at 1.5,
antialias on, one directional light with a 1024 shadow map that only covers the table, InstancedMesh or
shared geometry for tiles, merged static geometry with vertex colours for the room, MeshLambert or
MeshStandard materials, no post-processing, at most ~150 draw calls, generated textures created once
and reused, particles as one Points object. Pause animation work when the tab is hidden. Add a "?low"
URL flag that turns shadows off and lowers texture resolution.

SELF-TEST: add a "?auto" URL flag that plays the game by itself (solves each level with a real solver
over the puzzle state, not by reading the stored solution, and moves on) and a "?debug" flag that shows
draw calls and any JS errors on screen and exposes window.<game>Sim(seconds) to fast-forward without
rendering, so the game can be verified in a real browser without a human. Expose the live game state on
window.<game>.

Deliver only the finished index.html. No build step, no server needed: it must open by double-clicking
the file.
```
