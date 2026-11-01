---
name: vocabulary-budget-arithmetic
description: Why a per-archetype movement vocabulary has a hard floor of thirteen authored shapes, plus the absolute-path/formation exclusion and the arc's unused negative-ay direction
metadata:
  type: project
---

Learned writing the level-1 vocabulary in phase 11k (#320), on the owner's rule of "two or three
movements per archetype, resembling each other, mirrors free". Companion to
[[absolute-waypoint-authoring]] and [[carrier-spawner-survival-window]].

**The rule sets a floor and the brief's number was below it.** Six archetypes, each needing a simple
base *and* a complex one, is twelve; `enemy-rush` takes the third the design allots it, giving
**thirteen authored shapes minimum** — and the two forbidden pairs (`basic`/`shooter`,
`tank`/`carrier`) remove exactly the sharing that could have brought it under. The issue asked for
"nine or ten authored plus mirrors"; the rules cannot produce it. Count authored shapes, mirrors and
`speedOf` derivations separately and state the arithmetic, rather than trimming a family to hit a
number.

**An absolute (`waypoints`) path and a multi-slot formation are mutually exclusive.** A formation's
slots sit at `atX * 208 + offsetX`, and an absolute path only lands where written at one `atX`, so at
most one slot of a `pair` or a `line-3` could ever match. Any archetype that must be placeable in a
formation — carriers use `pair` in level 1 — has to keep its whole family relative. Decide this before
authoring, not after.

**`arc` with a negative `ay` was the missing direction, not a missing kind.** Every arc in the file
until 11k had `ay > 0` (decelerate, turn, climb back out the top), which is why arcs read as "veers"
and drift ±300 units. A negative `ay` accelerates the descent instead: it exits the *bottom*, quickly,
with a bounded horizontal drift — a usable "swoop that steepens". Reach for it before concluding a
curve is unsayable.

**A parked path is how a spawner's mechanism is guaranteed.** A `{wait: N}` leg is the only way to
promise screen time independent of speeds and edges: 14 s parked is five children at `interval 3.0`,
and it is arithmetic anyone can check in the JSON rather than an integration.

**The doc generator's geometry checks only cover waves a `level-NN.json` places.** They live inside
`buildLevel`, so a `test-` wave is listed `unplaced` and its swept extent and absolute `atX` are
**never checked** — including #300's new check. A vocabulary task therefore verifies its own `atX`
windows by integration; the generator only starts arguing when task 6 places the shapes.
