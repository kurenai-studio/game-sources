---
name: core-boundary-check
description: The mechanical check that catches an accidental core.domain import from game, and a real instance it caught in phase 03
metadata:
  type: project
---

`core`'s own architecture tests only scan `core/src/main/java` — they cannot see whether `game`, `desktop` or `web` import a concrete `core.domain` class, because nothing on the `game` side enforces the "no module exposes concrete classes to another" rule mechanically. There is no compiler error for this: `core.domain.*` classes are `public` (they have to be, for `core`'s own systems and tests), so they are importable from `game` without any build failure.

**How to apply:** before opening a PR from `game`/`desktop`/`web`, run `grep -rn "core\.domain\." game/src desktop/src web/src` (adjust paths to what actually exists). Zero matches is the bar; anything under `core.port` is fine, anything under `core.domain` or `core.application` internals is not.

**A real instance this caught in phase 03:** `LittleSpaceshipGame` initially imported `core.domain.system.MotionSystem` just to read its `PLAYFIELD_WIDTH` constant (208f) for centring the checkerboard backdrop. It compiled fine and worked correctly — the violation is architectural, not functional, so nothing would have flagged it short of this grep or a human reviewer. Fixed by duplicating the constant locally with a comment explaining why, tracing back to the same source document instead of the domain class.

The same applies to Javadoc `{@link}` tags: they don't create a real dependency (no import needed if fully qualified), but referencing a `core.domain` class in a `{@link}` still reads as coupling to whoever reviews the diff. Rewriting those as `{@code ClassName}` (plain text, no cross-reference) instead of `{@link core.domain....ClassName}` keeps the javadoc informative without implying the class is part of the contract.
