---
name: boss-aimed-fan-design
description: Redesigning BossSystem's fan from fixed outward/inward angles to aiming at the player — lock-then-fan for tell honesty, vector-only geometry, and the fixed-angle test that had to change
metadata:
  type: project
---

Phase 11e, issue #200, redesigned `BossSystem`'s spread/sweep fan to aim at the player instead of
fixed outward (spread) or inward (sweep) angles — the player's own diagnosis was that parking at
screen centre made both patterns harmless. Two techniques worth reusing anywhere else a fixed-angle
attack needs to start reading the player's position.

**Lock the aim once, well before it fires, not at the fire instant — that is what keeps a tell honest
under an aimed attack.** `lockAim(World)` runs once per pattern cycle, at the `COOLDOWN` → `TELLING`
transition, i.e. at the start of the 0.75 s tell, and every ray of the volley that tell resolves into
reads the frozen `aimX`/`aimY` rather than the player's live position. This preserves the same reaction
window the un-aimed fan already gave: the player dodges a point fixed before the charge started
reacting to them, not a shot that re-aims at wherever they are the instant it fires. Worth remembering
for any future "aim at the player" mechanic: locking early is the whole difference between a fair dodge
and a homing shot, and it costs nothing extra to implement — the state machine already has a clean
transition point to hang the read on.

**Fan geometry around an arbitrary direction, without `Math.sin`/`cos`, using only vector arithmetic
and `Math.sqrt`.** The previous fan used fixed per-ray `vx`/`vy` ratio constants — only possible
because the direction was always fixed. Aiming at a runtime point needs the direction computed, but
`core`'s own javadoc (kept from the original fan) already explains why a transcendental function is
off the table: `Math.sin`/`cos` are not guaranteed bit-identical between the JVM and TeaVM, which a
replay cannot afford. The fix: normalize the direction vector to the aim point with `Math.sqrt`
(IEEE-754 exact, already used the same way in `MotionSystem`'s velocity cap — check for existing
`Math.sqrt` precedent before assuming a `core` system can't touch it), take its perpendicular
(`(-uy, ux)`), add a scaled multiple of the perpendicular per fan ray, and renormalise each ray's
result to the pattern's fixed speed. Every ray still travels at exactly `speed`; only the direction
varies. This pattern generalises to any "aim a spread/fan at a moving target, deterministically" need.

**A rule-asserting test that names exact fixed values (old `vxRatios`) has to be deleted, not
adapted, when the rule itself changes — and a new test has to assert the new rule specifically, not
just "still compiles".** `BossSystemTest.volleyFansThreeRaysPerSideAndAlternatesPattern` asserted exact
`vx` magnitudes matching the removed constants; keeping it edited-in-place to match new numbers would
have hidden that the *rule* — fixed-angle fan — was gone, not just its numbers. Replaced with two
tests: one asserting the new invariant (every ray shares the pattern's fixed *speed*, direction no
longer fixed), one specifically exercising the lock-at-tell-start behaviour (move the player after the
tell begins but before the volley fires; assert the fan still points at the pre-move position). Both
plan.md and CLAUDE.md ask for this to be written down as "a rule changed", not silently edited — do
that in the status fragment every time, not just in the commit message.

Related: [[boss-fight-design]], [[boss-volley-density]], [[rng-teavm-constraints]].
