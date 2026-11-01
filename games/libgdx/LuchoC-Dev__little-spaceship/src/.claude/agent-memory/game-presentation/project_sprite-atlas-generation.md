---
name: sprite-atlas-generation
description: how the real sprite atlas is generated from docs/design/mockups/src/01-sprites.js, where region-name mismatches with the ECS live, and the legacy libGDX .atlas text format that already worked unverified
metadata:
  type: project
---

The single source of truth for pixel art is `docs/design/mockups/src/01-sprites.js`'s `SPRITES`
object (id -> {w, h, r, art}). `docs/design/atlas/build-atlas.js` (Node, no dependencies) rasterises
it straight into `assets/atlas/sprites.png` + `sprites.atlas`, which `PackedSpriteAtlas.load` already
picked up automatically — that composition-root wiring (`PlayScreen.atlas = PackedSpriteAtlas.load(...)`)
was already written and unused, waiting for a file that didn't exist yet. Regenerate with
`node docs/design/atlas/build-atlas.js` any time `01-sprites.js` changes; nothing else needs touching.

**Load the JS engine with `new Function`, don't reparse it.** `01-sprites.js` builds its wide,
mirrored archetypes by calling `sym([...])` inline inside the object literal. Concatenating
`00-palette.js` + `01-sprites.js` and running them through `new Function(src + 'return {...}')()`
(exactly what `docs/design/mockups/check.js` already does to run the mocks without a DOM) means
`SPRITES` arrives fully expanded and pre-validated by the file's own `validateSprites()` — a second,
Python-side reimplementation of `sym()` would be a second parser and a drift risk for nothing.

**The ECS's sprite ids do not all match the art's ids.** `PickupSystem.KIND_*`-derived ids
(`pickup-weapon-upgrade`, `pickup-extra-life`, `pickup-bomb-recharge`, `pickup-invulnerability`,
`pickup-attachment`) differ from what `01-sprites.js` proposed (`pickup-weapon`, `pickup-life`,
`pickup-bomb`, `pickup-invuln`, `pickup-module`). `BossSystem.SHOT_SPRITE` fires `boss-shot`, which
has no art entry at all anywhere — it was invented in phase 07 after the art pass. The atlas builder
handles both by writing alias regions (same packed rectangle, second name) rather than forking
pixels; `boss-shot` reuses `shot-e-small` because both are radius 2.0. This should be reconciled
properly (either core renames its ids or the art gains a `boss-shot` silhouette) the next time either
lane touches these files — the alias table in `build-atlas.js` is the one place tracking the gap.

**The legacy libGDX `.atlas` text format `build-skin.py` established (`docs/design/skin/skin.atlas`)
had never actually been runtime-verified** — nothing loads `skin.png`/`skin.atlas`/`skin.json` yet;
`GameSkin` builds everything in code. This atlas is the first thing in the repo to actually exercise
that format through `TextureAtlas`, and it loaded and rendered correctly on the first real
`:desktop:run` — worth knowing in case `skin.atlas` turns out to have a latent bug nobody has hit yet.

**`PackedSpriteAtlas.load`/`SpriteAtlas` interface and the `WorldRenderer`/`PlayScreen` wiring needed
zero code changes.** The only work was producing the file at the path they already expected
(`assets/atlas/sprites.atlas`) — a good sign the port/adapter boundary here was designed correctly
ahead of the art actually landing.

See [[windows-desktop-screenshot-verification]] for how this was confirmed visually (real cyan
`shot-p1` bolts, `enemy-basic` hexes, the ship's white damage-flash tint, all drawn from the real
atlas, not `PlaceholderAtlas`'s coloured rectangles).
