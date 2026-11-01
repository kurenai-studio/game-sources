---
name: boss-star-movement
description: How BossSystem's star patrol (issue #325) was made to never overlap firing, why an existing test needed a tick-budget fix rather than a behaviour revert, and how offline-derived geometry constants were made testable without a new port.
metadata:
  type: project
---

Issue #325 added movement to `BossSystem`: it now patrols the ten vertices of a five-pointed star
between attack cycles. A few things worth remembering that are not (or not fully) in the status
fragment `docs/plan/11k-level-one-rebuilt/status/325-boss-star-movement.md`.

**Serializing "fire" and "move" through the state machine itself, not a guard, is what makes "can an
attack overlap a move" answerable with certainty rather than "not observed."** `FightStage.MOVING` is
entered from exactly one call site — the last line of `updateTelling`, after `fire` already ran — and
`updateFight`'s `switch` means `updateCooldown`/`updateTelling` (the only places a tell advances or
fires) never run while `fightStage == MOVING`. This is worth reusing as a pattern whenever a task asks
"what happens if X is still resolving when Y would begin": look for whether the state machine's own
dispatch already makes the overlap structurally impossible before reaching for a boolean guard.

**An existing test that asserts "position never changes" is a load-bearing regression check for
exactly the behaviour a movement task is asked to remove.** `entranceDescendsToCombatY` drove 600 ticks
(10s) past the entrance ending, on the old assumption that nothing after `combatY` ever changed
position again. Adding movement made that assertion literally false after ~1s. The fix was not to
delete or weaken the assertion but to shrink the tick budget to a window that still proves the thing
the test's name claims (entrance settles at `combatY`) without wandering into the new behaviour the
task exists to add. Recompute the *minimum* ticks needed for the original claim, don't just pick a
smaller round number — the margin matters for whether the fix reads as principled.

**Star/waypoint literal constants needed test visibility, and the cheapest way to get it was dropping
`private` to package-private on the two float arrays**, not adding a getter or a testing port. Same
package (`BossSystemTest` lives in `core.domain.system`), zero new public surface, and it lets a test
assert against the literal values by name (`BossSystem.STAR_X[i]`) instead of re-deriving or duplicating
the trig by hand in the test.

**Deriving geometry offline (Python, not Java) and pasting the resulting literals with the script kept
in the status fragment reads as strong evidence** — a reviewer can rerun the five-line script and get
the exact same nine-decimal numbers, which is a stronger claim than "I computed this by hand" for a
task whose whole point is refusing runtime `sin`/`cos` under a TeaVM determinism constraint (see
[[project_boss-fight-design]] for the same reasoning applied to the aimed-fan geometry in phase 11e).

**A "pause at each waypoint" did not need its own timer.** The plan's own prose ("the boss arrives,
settles, and that is when an attack begins") already describes the minimal implementation: reuse the
existing `patternCooldown` + fixed tell duration as the stand time, and call `beginMove` from the tail
of the existing fire-completion code instead of looping back to `COOLDOWN`. Inventing a second,
independent "stop duration" constant would have been an unrequested extra knob. Worth checking, on any
task describing a "pause before X", whether an existing timer already produces exactly that pause as a
side effect before adding a new one.
