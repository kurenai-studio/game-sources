---
name: rng-teavm-constraints
description: Why the core Rng uses only xor and shifts, and what would silently break it
metadata:
  type: project
---

The core `Rng` is a 32-bit xorshift written with `^`, `<<` and `>>>` only. Integer multiplication is avoided deliberately.

**Why:** the stream has to be identical on the JVM and under TeaVM. JavaScript numbers are doubles, so a 32-bit product leaves the range where they are exact and the result depends on how the transpiler emulates the operation. Xor and shifts have identical semantics on both. `nextFloat` is built from the top 24 bits times an exact power of two, so the conversion cannot round differently either.

**How to apply:** any change to the generator, or any new derived value, has to stay inside those operations. A divergence here shows up days later as a replay that only fails on web, looking like a gameplay bug. `RngTest` pins three sequences; if it fails, the question is whether the algorithm changed on purpose, because every recorded replay depends on it.

**The same caution applies outside `Rng` too, to any transcendental function.** Phase 07's `BossSystem` needed angled projectile velocities (a spread/sweep firing pattern) and deliberately avoided `Math.sin`/`Math.cos` for them, using fixed precomputed ratio constants instead — `Math.sin`/`cos` are not guaranteed to produce the bit-identical float on the JVM and under TeaVM, the same class of risk as integer multiplication in the generator, just outside `Rng` itself. `DeterminismRulesTest` does not grep for `Math.sin`/`cos` (only `Math.random`), so this one is not caught by the automated check — it has to be caught by review or by remembering this note.

Related: [[core-boundary-decisions]], [[phase-01-foundations]].
