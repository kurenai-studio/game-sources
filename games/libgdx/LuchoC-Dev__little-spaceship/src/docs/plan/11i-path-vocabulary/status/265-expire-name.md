# 265 — expireProjectiles renamed to expireProjectilesAndPickups

Closes #265. Branch `refactor/expire-name` against `phase/11i-path-vocabulary`.

## What changed

- `core/src/main/java/dev/luchoc/littlespaceship/core/domain/system/LifetimeSystem.java` —
  private method `expireProjectiles` renamed to `expireProjectilesAndPickups`, matching what
  issue #260 already made it do (it matches `CollisionLayer.PICKUP` alongside both projectile
  layers). No other reference to the old name existed: `grep -rn "expireProjectiles\b"
  --include=*.java .` finds only the declaration and its one call site, both in this file — the
  method is private, called once, from `update`.

## Why this name and not another

The method does one thing, expressed once: destroy any entity of a small, fixed set of layers
once it has passed a fixed margin outside the playfield. Naming that set literally
(`expireProjectilesAndPickups`) was chosen over a more abstract alternative
(`expireOffPlayfieldEntities` or similar) because the class javadoc already frames "projectiles
and pickups" as one deliberate group sharing one check, distinct from "enemies" getting two
separate mechanisms just below it in the same file — so the method name now echoes the same
grouping the prose already draws, rather than inventing a new vocabulary for it.

Not awkward enough to be a finding: the method really does only these two things, by the same
check, for the same reason (bounded growth over a multi-minute level). It is not doing two
unrelated jobs that should split — it is doing one job (position-based expiry) over one set of
layers that happens to have two names.

The class javadoc and `PROJECTILE_MARGIN`/`isPastProjectileMargin` were left untouched: the
javadoc already describes the pickup case correctly (added in #260's own PR), and renaming those
was explicitly out of scope per the issue ("Everything else in `LifetimeSystem` ... is #261, in
`game/`" — and the constant/predicate names are not the object of this issue in any case).

## Invariants

- No behaviour change: same layer check, same margin, same call site, only the identifier
  changed.
- `core` imports no libGDX, reads no clock, calls no `Math.random()`, spawns no thread —
  unaffected, this is a rename only.

## Commands run and their output

```
$ ./gradlew :core:test --console=plain
BUILD SUCCESSFUL in 7s

$ find core/build/test-results -name "*.xml" -exec grep -oh \
    'tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*" errors="[0-9]*"' {} \; \
    | awk -F'"' '{t+=$2;s+=$4;f+=$6;e+=$8} END{print "tests="t, "skipped="s, "failures="f, "errors="e}'
tests=351 skipped=0 failures=0 errors=0

$ ./gradlew build --console=plain
BUILD SUCCESSFUL in 3s
(all modules: core, rngparity, game, web, desktop — green)
```

## Running the game

Not checked — a rename with no behaviour change does not need it, and playing to confirm is out
of bounds regardless.
