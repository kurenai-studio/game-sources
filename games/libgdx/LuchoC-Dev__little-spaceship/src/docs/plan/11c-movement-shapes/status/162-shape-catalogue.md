# 162 — Which movement shapes exist

**Task 2** · closes [#162](https://github.com/LuchoC-Dev/little-spaceship/issues/162) · branch `content/movement-shapes`

## What was done

[`shape-catalogue.md`](../shape-catalogue.md) decides the catalogue: **two kinds and seven entries**,
each entry pointed at a beat of level 1. Nothing in it is built — this is the design decision #163
turns into a contract and a loader and #164 puts on a `SpawnEvent`.

- **`constant` `{vx, vy}`** — what ships today. The four entries in `assets/data/trajectories.json`
  are `constant` shapes and are unedited, which is the criterion the issue set.
- **`arc` `{vx, vy, ay}`** — constant horizontal velocity plus constant vertical acceleration:
  `velocity(t) = (vx, vy + ay·t)`. It is the roadmap's U-shaped attack run, and because it is a
  parabola the turn reads as a turn rather than as a ricochet. It turns at `t = -vy/ay` and its apex
  sits `vy²/(2·ay)` below where it spawned, which is how a designer aims it at the band the player
  flies in (`playerStartY` 30).
- **Three new entries**, all `arc`: `strike-run` (beats 7, 11, 13), `veer-left` and `veer-right`
  (beats 10 and 13). Each is checked against the playfield and against the safety box, and the
  document states when each one leaves.

## The decisions the issue did not specify

- **Acceleration rather than a segment list.** A "descend, then reverse" piecewise shape gives the
  same U on paper and a bounce on screen. Three numbers beat a list, and the two derived quantities
  above make the shape aimable instead of tuned by trial.
- **No content was written.** `assets/data/` is this agent's, but `JsonContentSource.loadTrajectories`
  (`game/.../JsonContentSource.java:157-166`) reads exactly `id`, `vx`, `vy` and ignores unknown keys.
  An `arc` entry added today would load, resolve, and fly as a constant with nobody told — content
  that looks correct and is not. The entries land in #163's pull request, beside the parser that
  reads them.
- **A shape must leave the playfield unattended, in finite time**, and it is written into the
  catalogue as a rule rather than as a property of the entries. `LifetimeSystem` removes an enemy only
  once it is off screen, so an entity that comes to rest inside the playfield would let a `cleared`
  wave deadlock behind something the player is not obliged to kill. That is also why
  `enterAndHold` is refused rather than deferred politely.

## What was refused

Eight things, with reasons, in the document's own table: a `diagonal` kind (it is `constant` with a
chosen `vx`), a `logarithmic` kind, a `sine`/weave, `enterAndHold`, horizontal acceleration,
waypoints and splines, formation-relative shapes, and anything reading the player. The sine is named
as the **first candidate to revisit** if 11e plays beat 10 and finds crossing arcs do not move the
safe corridor enough, so the next person does not re-derive it from scratch.

## The finding worth carrying to phase 12

**Phase 12's levels 2 and 3 justify no shape in this catalogue, and could not.** They have no beat
list: `post-mvp-roadmap.md` says what they are *for*, and `04-campaign-and-levels.md` gives stage 1
one evolution sentence. The issue asked for shapes "level 1's fourteen beats **and phase 12's two
levels** can point at"; only the first half of that could be answered honestly, so all seven entries
rest on level 1. When level 2 is designed and names something this catalogue cannot express, that is
the case that adds the next kind.

## Open

- Whether `arc`'s velocity is evaluated per tick and Euler-integrated, or its position taken in closed
  form. The two differ by `½·ay·dt·t` — about 0.9 units after 4 s at `ay = 27`, invisible and
  deterministic either way — but #163 should pick one deliberately and let the test assert it.
- Whether the vocabulary is renamed from "trajectory" to "movement". The catalogue recommends **not**
  inside this phase: it is more honest and it costs a rename across content, `JsonContentSource`,
  `TrajectoryDefinition` and `ComponentFactoryRegistry` for no behaviour change.
- The numbers in the entries are aimed, not played. Nobody has flown against a `strike-run`; 11e is
  where playing decides, and the apexes are stated so they can be moved by a known amount.

## For whoever comes next

Level 1 is **not** edited here, deliberately — that is [11e](../../11e-level-one-redesigned/plan.md).
The beat table in the catalogue is a map of what asks for what, and 11e is free to disagree with it
as long as it disagrees on purpose.
