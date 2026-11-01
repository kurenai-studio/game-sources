---
name: architecture-test-narrowing-has-no-fixture-seam
description: PublicContractTest and LayerDependencyTest scan real core sources, not fixtures — narrowing them is proven by planting-and-reverting on a real file, not by a permanent fixture test
metadata:
  type: project
---

`PublicContractTest` and `LayerDependencyTest` both drive off `CoreSources.all()` — the project's real
`.java` files, read from disk by path/package/import text, not a fixture string handed in by the test.
That is unlike `JavaSource.strip` (phase 11a task 5a), which is a pure string transform and so can carry
permanent fixture tests such as `ignoresAForbiddenNameInsideAStringLiteral`.

**Consequence for "narrow the check, then prove it still catches something":** there is no fixture seam
to assert against without either creating a fake source file the scanner would pick up (out of scope —
`CoreSources` itself lives under `core/src/test`, arguably fair game, but it changes the scanning
mechanism, not the rule) or editing `core/src/main` (outside `test-engineer`'s boundary even
temporarily-and-reverted, except as a deliberate plant-and-revert demonstration). The pattern that
worked: add a tiny, clearly-marked planted violation to a real `core/src/main` file (an unused public
method or an unused import), run the test before the narrowing to show it wrongly passes, narrow the
check, run again to show it now fails with the exact assertion line, then `git checkout --` the planted
file and confirm the full suite is green again with the narrowing in place against real code. `git diff
-- '*/src/main/*'` empty at the end is the check that nothing survived.

Two concrete planting spots that worked without needing new files: `MapComponentSpec` (concrete class in
`core.port`, add a public method returning `ArrayList`) for `PublicContractTest`'s `java.util` narrowing,
and `SpriteVisitor` (interface in `core.port`, add one unused import of `core.domain.collision.
CollisionHit`) for `LayerDependencyTest`'s domain-package whitelist. Both are low-traffic files, so the
plant is easy to spot and revert cleanly.

Related: [[project_boss-replay-geometry]] and [[feedback_verifying-dead-conjuncts]] are the same family
of "plant it, show it caught, revert" evidence discipline, applied to a different kind of check.
