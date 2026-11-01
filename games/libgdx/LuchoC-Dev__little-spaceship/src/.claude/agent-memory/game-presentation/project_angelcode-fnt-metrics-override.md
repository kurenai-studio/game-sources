---
name: angelcode-fnt-metrics-override
description: how to hand-write a plain AngelCode .fnt for a uniform-grid bitmap font so BitmapFont.draw's y lands where the caller expects, without per-glyph AABB metrics
metadata:
  type: project
---

Building `assets/fonts/font-mini.fnt`/`font-title.fnt` (phase: real bitmap fonts, PR branch
`fix/real-bitmap-fonts`) from the uniform-grid sheets `docs/design/03-typography.md` specifies (every
glyph is the full cell, no per-glyph metric table) ran into two libGDX 1.14.2 `BitmapFontData.load`
behaviours that cost real time to work out — read from the actual source
(`gdx/src/com/badlogic/gdx/graphics/g2d/BitmapFont.java`), since neither is documented on the
class javadoc:

1. **The "metrics" override line is silently ignored unless preceded by a "kernings count=" line.**
   `load()`'s char-reading loop breaks out with `line` holding whichever line stopped it
   ("kernings " or "metrics "). But the *next* block — nominally for reading `kerning ` lines —
   unconditionally calls `reader.readLine()` first, discarding that held line before ever checking
   it. So a `metrics` line with no `kernings count=` line before it gets silently skipped: the file
   parses without error, but every metrics value you wrote is ignored and the loader falls back to
   AABB-derived ones instead. Fix: always emit `kernings count=0` immediately before the `metrics`
   line, even with zero kerning pairs.

2. **With every glyph's texture region set to the full cell** (this project's whole point — "no
   glyph needs a Y offset", per `03-typography.md`), `capHeight`/`ascent`/`descent` auto-derived from
   glyph AABB height would read the *cell* height (10px/13px) as the cap height, not the true ink cap
   height (7px/11px) — pushing every line down by the difference. The `metrics` override line
   sidesteps this by supplying `ascent`/`descent`/`down`/`capHeight`/`lineHeight`/`spaceXadvance`/
   `xHeight` directly. Derivation that produced correct pixel-exact top-of-cell alignment with
   `BitmapFont.draw`'s "y is the top" contract (`flip=false`, `addGlyph` places quad bottom at
   `y + ascent + glyph.yoffset`, top at that + glyph height):
   - `ascent = -lineHeight` (cell height), `down = -lineHeight`
   - per-char `yoffset` token in the `.fnt` = `-cellHeight` (so `BitmapFontData`'s flip=false
     conversion `-(height + writtenValue)` nets to internal `yoffset = 0`)
   - `descent = -(cellHeight - baselineRow)`, `capHeight`/`xHeight` = the doc's real values (7/5 for
     mini, 11/11 for title) — these don't affect `draw()` positioning under this override but do feed
     `GlyphLayout.height` (`capHeight + extra-lines*|down|`), which is what `scene2d.ui.Label` uses
     for vertical centering, so they should be the true values, not cell height.

Confirmed correct on-screen at scale 1 across menu, ship select, options, pause and defeat screens —
no half-pixel or off-by-one-line symptoms. The generator itself is
`docs/design/fonts/build-fnt.js` (Node, mirrors `docs/design/atlas/build-atlas.js`'s
"committed script → committed asset" pattern); it copies the already-built PNGs verbatim rather than
re-rasterising, since `docs/design/fonts/build-fonts.py` already owns that step.
