---
name: absolute-waypoint-authoring
description: What an absolutely-authored waypoint path is really absolute in — x only if the wave's atX matches the entry point, and y only modulo the collider radius — plus the doc generator's blind spot for path entries
metadata:
  type: project
---

Learned adding seven trajectories in phase 11j (#297). Companion to [[path-shape-authoring]] and
[[shape-placement-arithmetic]].

**A `waypoints` path is not absolute by itself — the wave has to agree.** `SpawnSystem.positionSpawned`
puts the slot at `x = atX * 208`, and the path only ever adds deltas to that; the entry waypoint's
coordinates are an *authoring* origin that the engine never reads. So the coordinates only mean what
they say when the placing wave uses **`atX = entryX / 208`**. Pick entry-x values that give a round
`atX` (20.8 -> 0.10, 104 -> 0.50); an ugly `atX` is a sign nobody will get it right twice.

**And it is absolute in `y` only modulo the collider radius.** The slot is born at `y = 270 + radius`,
so a waypoint written `y: 190` is flown at `190 + radius`. Measured: `enemy-shooter` (radius 6.5) held
at **196.4**, and a leg written at `y: 214` crossed at **220.1**. Small, predictable and enough to ruin
"these two shapes line up at the same height" if the two archetypes have different radii. Author the
waypoint, then say the flown height in the description — do not claim the waypoint's own number.

**Nothing checks either condition, at load or in the build.** `JsonContentSource` parses
`trajectories.json` and `waves.json` independently with no cross-reference in the class, so a wrong
`atX` is a shape merely in the wrong place — the hardest content bug to see. The right home for the
check is `tools/build-level-docs.js`, which already reads both together and already fails a PR on a
swept extent leaving the playfield. Not `level-designer`'s file to edit; recommend it as an issue.

**The doc generator does not understand `path` at all.** `sweptExtent`/`screenTime` read `vx`/`vy`/`ay`
only, and a `mirrorOf` entry has no velocity fields whatsoever. Nothing broke in 11i or 11j because
every `path` and mirror is reachable only from `test-` waves, which no level places — the generator
resolves trajectories through level-01's spawns and archetype defaults. **The first `path` placed in
`level-01.json` is the moment that stops being true**, and 11k is that moment. Expect to have to check
what the generator does with it before placing one.

**Two things that were confirmed cheap and worth repeating:** a `constant` is still the right answer for
anything straight (a one-segment `path` for a diagonal buys nothing and dilutes what `path` means in the
file), and a `mirrorOf` works on a `constant` as well as on a `path` — `mirror()` switches on the record
type, so a plain `{vx, vy}` entry mirrors in one line just like a path does.
