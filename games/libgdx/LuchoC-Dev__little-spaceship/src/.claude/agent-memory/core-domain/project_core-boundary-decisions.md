---
name: core-boundary-decisions
description: How the core boundary is shaped and enforced, beyond what docs/planning states
metadata:
  type: project
---

Decisions taken while implementing phase 01 that tighten the sketch in `docs/planning/12-architecture.md`.

**Why:** the architecture document sketches the boundary; these are the choices made when the sketch met the compiler. They are recorded in `docs/plan/01-foundations/status.md` too, but the reasoning behind them matters when the next phase is tempted to loosen one.

**How to apply:** keep these when adding to the core; if one gets in the way, that is worth raising rather than working around.

- `Simulation` takes an `int` seed, not an `Rng`. The architecture example builds the generator in the composition root; taking the seed makes it impossible for `game` to inject another source of randomness.
- `World` does not implement `WorldView`. It hands out a private inner class, so nobody can cast the view back into something mutable.
- `World` does not run the systems and does not know they exist. `Simulation` owns the pipeline. That is what keeps `domain` from importing `application`.
- Tests build a `Simulation` with their own systems through a package-private constructor. That is how determinism is tested with no game rule implemented.
- The forbidden API check is a plain text search, not a comment-aware one, so it finds exactly what a reviewer greps by hand. Consequence: **no comment anywhere in `core` may spell out `Math.random`, `java.util.Random`, `System.nanoTime`, `System.currentTimeMillis`, `com.badlogic.gdx`, `Thread`, `ExecutorService`, `CompletableFuture`, `ReentrantLock` or `synchronized`**. The `Rng` javadoc talks around two of them and says why.
- `GameLoop` accumulates in `double` while handing systems the fixed `float` step. A float accumulator turns one second into 59 ticks at some frame rates and 60 at others.

See [[phase-01-foundations]] for what was deliberately left out, and [[rng-teavm-constraints]] for why the generator looks the way it does.
