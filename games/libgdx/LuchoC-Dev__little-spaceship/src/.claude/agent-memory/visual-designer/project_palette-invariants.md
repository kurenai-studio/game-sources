---
name: palette-invariants
description: The three palette rules that must never be relaxed, and why each exists
metadata:
  type: project
---

**Why:** the palette looks like taste and is not; each of these three properties is load-bearing, and any of them can be relaxed by someone who thinks they are choosing a nicer colour.

**How to apply:** run `check.py` before believing a palette change is harmless, and treat these three as the rules that outrank a nicer-looking frame.

The `ls32` palette is not a mood board, it is an enforcement mechanism. Three properties carry it,
and the documents in `docs/design/` are only their explanation:

1. **Background-legal and gameplay-only are disjoint sets.** A background cannot swallow a bullet
   because the colours that would make it bright are not available to it. Relaxing this turns every
   legibility rule back into something people have to remember.
2. **Hues 320-350 belong to enemy fire, campaign-wide.** This is why stage 4's biomechanical tissue
   is violet and its dark organics are maroon-brown: pink was already spent.
3. **The lightness gap is 3.2 points** — backgrounds stop at `L*` 44.9 (N4), gameplay starts at 48.1
   (V4). It looks like a small margin and it is not: enemy fire sits 13 points above the ceiling
   with its body and 45 with its core.

`docs/design/palette/check.py` recomputes all of it. If a colour is ever added, run it before
believing the palette still works.

**Two traps found while choosing the colours.** Maroon drifts into the reserved band without
looking like it does: `#5E2A33` reads as brown and measures hue 350. And the Moon is the stage that
breaks the ceiling first, because lunar rock wants to be white — it is drawn at N4 instead, which
reads as bright rock against an N1 sky.

Related: [[hud-and-size-constraints]]
