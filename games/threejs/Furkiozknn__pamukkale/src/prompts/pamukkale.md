# Arena round 6, game 4: Pamukkale (water-flow terrace puzzle) — built by Claude Haiku 5.5

```text
Build a single-file browser game (one index.html with inline CSS and JS) using Three.js r170 loaded as an ES
module from https://cdn.jsdelivr.net/npm/three@0.170.0/ (import map; addons from examples/jsm/).
A calm 3D puzzle game called "Pamukkale" about the white travertine terraces. Do not ask questions, build it
end to end.

WORLD: a bright white hillside of travertine terraces with shallow turquoise pools, seen from a slightly raised
3/4 view. Around it: green hills, poplars, the ruins of an ancient city (columns, a theatre) at the top, a blue
sky with soft clouds, golden light at sunset levels. Palette: white and cream terraces, turquoise water
(#2EC4C9 accent), green land. The terraces must look smooth and rounded (curved rims, layered shelves), never
like plain boxes.

CORE MECHANIC: a simple grid water simulation (height per cell, water flows downhill to neighbours each step).
Warm water comes out of a spring at the top. The player places a limited number of tools on the grid:
- channel stones that guide the flow,
- small dams that hold water back,
- splitters that divide a stream.
Each level has target pools that must be filled to their mark. Where water stands still for a while, calcium
slowly builds a new white rim, so the terrace shape grows over time (a slow, satisfying change the player can
plan for). Overflow running off the edge is wasted; the level counts water used.

CONTENT: 20 short levels in 4 areas (lower pools, middle shelves, the ancient pool, sunset). Stars for filled
pools, water used and tools left. Level data in one table; every level must be solvable by the bot.

INTERACTION: click or tap a cell to place the selected tool, right-click or long-press to remove, 1-3 select a
tool, Space start / pause the water, F fast-forward, R reset, Z undo; drag to orbit a little, wheel or pinch to
zoom.

HUD: top bar (logo, level, pools filled, water used, stars, pause, sound, language), tool tray, toasts, title,
area map with level stars, level result, ending at sunset with the whole hillside full of pools.

EXTRAS: water trickle and splash sounds, birdsong, a calm saz-and-flute loop, all synthesised (CC0 one-shots
from asset-forge allowed).
```

The shared rules in `_sablonlar/arena-round6-common.md` are appended to this prompt.
