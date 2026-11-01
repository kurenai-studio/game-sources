---
name: hud-icon-wiring-and-satellite-with-no-core-entity
description: how issue #43 (shield/attachment invisible) was actually a wiring task against already-packed atlas art, and how a component with no Transform still gets drawn following the ship
metadata:
  type: project
---

`assets/atlas/sprites.atlas` already carried `icon-life`, `icon-bomb`, `icon-shield`, `icon-invuln`,
`icon-module` (all sized to exactly the pixel dimensions `docs/design/04-hud-layout.md`'s tables
already fixed) and `module-satellite`, referenced by nothing. `HudRenderer` was still drawing all six
plate slots as flat rectangles — its own class javadoc and `04-hud-layout.md`'s "What each slot looks
like" both already said so ("Specified, not drawn", recorded 26/08/2026). Confirming this cost one
`grep`/`awk` pass over the `.atlas` file, not a design conversation — check the packed atlas's own
entries before assuming a phase issue means new art work.

**Wiring pattern that worked**: give `HudRenderer` the same `SpriteAtlas` `WorldRenderer` already
has (it was previously font/pixel-only), resolve the five `icon-*` regions once at construction, and
at each draw site fall back to the pre-existing rectangle when the resolved region is `null` — this
matters because `PlaceholderAtlas` (the no-packed-atlas fallback) does not cover HUD glyphs at all,
so a naive replacement would NPE on any checkout that has not run `build-atlas.js`. Same
missing-region tolerance `WorldRenderer` already had for world sprites, just needed for HUD too.

**`core.domain.component.Attachment` has no `Transform`/`Sprite`** — it is a plain field
(`id`/`durability`) on the player entity, not its own ECS entity. `WorldView.forEachSprite` never
visits it. "Draw the attachment following the ship" therefore has no independent position to read:
the fix is to draw the satellite sprite at an offset from the *player's own* `x`/`y` inside
`WorldRenderer.accept()`'s existing player branch, which already runs once per frame at the ship's
live position — no new port, no new state to keep in sync, it just piggybacks on the call that
already happens. If a future task needs the satellite's `x`/`y` to be simulated independently (e.g.
two satellites orbiting), that would need a real core change; a single fixed-offset flank did not.

**Shield state has no on-ship representation by design**, not by omission. `04-hud-layout.md`'s "the
ship, not the plate" section is scoped in its own table to the three `InvulnerabilitySource` grace
periods (respawn/damage/power-up); the shield layer (`shieldActive`) is a separate concept and the
document only ever specifies a HUD icon for it. Do not invent an on-ship shield ring to "finish" the
issue — check the design doc's actual scope for the feature named in an issue title before assuming
the issue wants every possible representation of it.
