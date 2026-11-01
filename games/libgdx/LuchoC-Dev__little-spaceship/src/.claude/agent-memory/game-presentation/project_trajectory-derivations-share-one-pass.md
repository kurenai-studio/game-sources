---
name: trajectory-derivations-share-one-pass
description: Why speedOf joined mirrorOf as a second "derivation" in one resolution pass, the arc ay-squared result, and how the geometry claim was mutation-checked
metadata:
  type: project
---

Built for issue #296 (phase 11j task 2), in `JsonContentSource`. `{"id", "speedOf", "multiplier"}`
declares a trajectory as another one traversed faster.

**Two "derivation" keys, one resolution pass.** `mirrorOf` (#264) and `speedOf` are both "name another
trajectory instead of a `type`", so `resolveMirror` became `resolveDerived` and dispatches on which key
the entry has. Cycle detection, order-independence and derivation-of-a-derivation came for free, and a
mirror of a faster and a faster of a mirror both work with no extra code. A third derivation is a
branch plus a builder beside `mirror`/`faster`. Related: [[project_trajectory-mirroring-and-core-exceptions-without-ids]].

**The non-obvious arithmetic: an `arc`'s `ay` takes the *square* of the multiplier**, while its
velocities take the first power. From `y = vy·t + ay·t²/2`, the substitution `t -> k·t` is what keeps
the parabola pointwise identical; scaling `ay` linearly — which "make it all faster" suggests — silently
produces a *different curve* of the same family, so it would look plausible on screen. This is the one
place where "same shape, traversed sooner" is not "multiply everything".

**A geometry-preservation claim is only worth what its mutation run shows.** The trap named in the task
was a test where the loader agrees with itself. Two things kept it honest: the tests integrate `core`'s
own `horizontalVelocityAt`/`verticalVelocityAt` (left-endpoint Euler; exact for a piecewise-constant
`path` when segment boundaries land on sample boundaries, and — worth knowing — the fast and original
Euler sums are *algebraically identical* for an `arc` too, since `v'(t/k) = k·v(t)`, so the integration
error cancels and no tolerance fudge is needed for the comparison), and the expected positions are
worked out by hand in the comment above each fixture. Mutating `faster` to the *other* meaning of faster
(a `scale`: durations untouched, `ay × k`) turned exactly the five geometry tests red.

**Verifying that the shipped `assets/data` still parses without touching it**: drop a throwaway JUnit
test in `game/src/test/.../content/` doing
`new JsonContentSource(new FileHandle(new File("../assets/data")), "level-01")`, run
`./gradlew :game:test --tests '*Tmp*'`, delete it. Working directory for a `:game` test is the module
directory, hence `../assets/data`. Launching the desktop game proves nothing about content: real content
is only constructed in `PlayScreen` and `ShipSelectScreen`, i.e. past the menu, which an agent must not
navigate — see [[feedback_agent-must-not-play-the-game-to-verify]].
