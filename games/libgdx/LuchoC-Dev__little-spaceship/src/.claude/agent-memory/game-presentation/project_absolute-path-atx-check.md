---
name: absolute-path-atx-check
description: How build-level-docs.js checks an absolute path's placement against its required atX (#300), and why a mirrored entry point reflects rather than negates
metadata:
  type: project
---

Built in phase 11k, issue #300, on top of #310's trajectory resolution and #314's trailing-edge
fix (same file, [[project_build-level-docs-path-trajectory-resolution]] and
[[project_pathsweep-leading-vs-trailing-edge]]).

**A `waypoints`-authored path's first waypoint is an authoring origin, and it survives resolution as
`entryX` on the uniform resolved shape**, set only when `hasWaypoints` (never for `segments`, which
is written as deltas and has no absolute position). Everything downstream that builds a derived
trajectory has to decide what to do with a field it never used to carry:

- `mirrorOf` **reflects** `entryX` across the playfield centre — `width - entryX` — not negation.
  Confirmed against both shipped mirror pairs before writing code (`descend-and-turn-left`/`-right`
  at `atX 0.85`/`0.15`, summing to `1.00`), but neither of those two is authored with `waypoints` —
  they use `segments`, so they carry no `entryX` at all and cannot actually exercise this. The check
  can only be exercised on a scratch fixture mirroring one of the two real `waypoints` entries
  (`hold-the-line-and-exit`, entry `x 104`, exactly the centre — useless for telling reflection from
  negation since both give the same answer; `sweep-the-width-and-drop`, entry `x 20.8`, mirrors to
  `x 187.2` and requires `atX 0.90` — this is the one that actually distinguishes the two). **Always
  pick the off-centre fixture when validating a reflection**, the centred one will pass either way and
  prove nothing.
- `speedOf` carries `entryX` through unchanged — scaling speed does not move the entry point.

**Tolerance derivation that generalises beyond this one check**: when a value is authored to N decimal
places and then multiplied by a constant, the largest gap a *correct* value can have from the exact
target is half of the smallest representable step, scaled by the constant — here `0.005 * 208 = 1.04`
screen units for a two-decimal `atX`. A tolerance just past that (chosen: `1.1`) is comfortably clear
of the smallest possible real mistake (a full one-hundredth of `atX`, `2.08` units), so the exact
value inside that gap is not load-bearing. This is the same shape of derivation the file's own
`Math.abs(x) < 0.05` "same" comparisons use elsewhere for floating-point noise, but here the noise is
authoring-precision noise, an order of magnitude larger, and worth writing down as its own constant
with its own justification rather than reusing `0.05`.

Verification method: add fixtures to scratch copies of `waves.json`/`trajectories.json`, generate,
read the Checks section, then `git checkout --` both files. No level file placing a `path` needed to
be created and deleted separately — `level-99.json` plus the two data files sufficed, then all three
were reverted (`git status --porcelain` clean throughout).
