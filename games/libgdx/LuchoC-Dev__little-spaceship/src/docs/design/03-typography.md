# Typography

Two bitmap fonts, both drawn by hand as PNG sheets. No TrueType, no `FreeTypeFontGenerator`: at
480x270 a scalable font produces blurred, half-pixel glyphs, and the generator is one more thing to
verify under TeaVM.

## `font-mini` — everything the player reads

The working font. HUD labels, menu entries, options, credits, ship characteristics.

| Property | Value |
|---|---|
| Glyph box | 5 x 7 px |
| Cell in the sheet | 6 x 10 px |
| Cap height | 7 px, rows 0-6 of the cell |
| x-height | 5 px |
| Descender | 2 px, rows 7-8, for `g j p q y` |
| Baseline | row 7 of the cell |
| Advance | 6 px, fixed |
| Line height | 10 px |
| Coverage | ASCII 32-126, 95 glyphs |
| Sheet | 16 columns x 6 rows = 96 cells, **96 x 60 px** |
| File | [`fonts/font-mini.png`](fonts/font-mini.png) |

The advance is **fixed**, which makes every number tabular for free: a score does not jitter as its
digits change, and the width of a string is `characters * 6` without measuring anything. At this
size proportional spacing buys a few pixels and costs a moving HUD.

The 96th cell is left empty; it is spare, not a glyph.

## `font-title` — screen titles and the score

Used in exactly two places: the title on each screen, and the score value in the HUD. Everywhere
else uses `font-mini`.

| Property | Value |
|---|---|
| Glyph box | 7 x 11 px |
| Cell in the sheet | 8 x 13 px |
| Baseline | row 11 of the cell |
| Descender | none |
| Advance | 8 px, fixed |
| Line height | 13 px |
| Coverage | `A-Z`, `0-9`, space, `. , : - ! ?` - 43 glyphs |
| Sheet | 16 columns x 6 rows, **128 x 78 px**, 43 cells filled |
| File | [`fonts/font-title.png`](fonts/font-title.png) |

Uppercase only, and there is no lowercase to fall back to. A string with lowercase in it is a
mistake in the caller, not in the font: **nothing uppercases on the way out**, so it draws as gaps.
An earlier version of this page said the loader uppercases before drawing; it never did, and the
only `toUpperCase` in the project turns a content id into a HUD plate label
(`HudRenderer.attachmentLabel`). Corrected 26/08/2026.

The sheet was specified here as 10 x 4 = 40 cells at 80 x 52 px, and that was wrong: the coverage
above is 43 glyphs and never fitted in 40 cells. Corrected on 22/08/2026 while drawing it, and
corrected *upwards* rather than by cutting punctuation, because the fix is described below and it
costs nothing worth having.

It is a **hand-drawn** font and not `font-mini` scaled x2. Scaling would be exact, since only
integer factors are allowed, but a 10x14 letter made of 2x2 blocks reads as a placeholder.

## The sheet, and how the code lane reads it

**Both sheets use the same grid**: 16 columns, one cell per ASCII code from 32 to 126, row-major.

    cell index  = code - 32
    cell column = index % 16
    cell row    = index / 16

That is the whole loader. `font-title` covers only 43 of the 95 codes and the rest of its cells are
transparent, which wastes 5 KB of texture and buys one indexing rule instead of two. It also means
an unsupported character draws as a blank rather than as whatever glyph happened to sit at that
offset, which is the failure mode worth paying for.

| Font | Sheet | Cell | Glyph box | Origin inside the cell |
|---|---|---|---|---|
| `font-mini` | 96 x 60 | 6 x 10 | 5 x 7, descenders to 9 | top-left, 0, 0 |
| `font-title` | 128 x 78 | 8 x 13 | 7 x 11 | top-left, 0, 0 |

The glyph is drawn at the cell's top-left corner; the spare column and rows on the right and bottom
are the advance and the line gap, already inside the cell. So the code lane can take the whole cell
as the texture region and step by the cell width - there is no per-glyph metric table, no kerning
pairs and no XML. A `BitmapFont` built from a `.fnt` would work; so would a hand-built
`TextureRegion[95]` indexed by `code - 32`, which is one loop and no parser, and is what this font
was drawn for.

Descenders live **inside** the cell: `g j p q y , ;` occupy rows 7-8 of a 10-row cell, so nothing
overflows and no glyph needs a Y offset.

**The sheets are generated, not hand-edited.** The glyph bitmasks live in
`mockups/src/00-palette.js`, because the mock pages draw text with them and a font that exists in
two places diverges. Two scripts turn them into files, and both are needed:

```
python docs/design/fonts/build-fonts.py   # the sheets, into docs/design/fonts/
node   docs/design/fonts/build-fnt.js     # the game's fonts, into assets/fonts/
```

`build-fonts.py` writes `font-mini.png`, `font-title.png` and `specimen.png`. The specimen is both
fonts set as running text at 4x, and it is there because a sheet of glyphs in a grid does not tell
you whether a sentence reads.

**`build-fnt.js` is the one that puts the fonts in the game**, emitting the AngelCode `.fnt` and its
page into `assets/fonts/`, which is what `GameSkin` loads. It was added on 25/08/2026 and this page
did not mention it, so following this page produced sheets nothing could load — which is exactly what
happened: every screen rendered in libGDX's bundled Arial until the gap was found.

## How both are drawn

**White on transparent.** One sheet per font, every glyph in `N7`. Colour comes from the batch tint
at draw time, so a label in `N4` and a value in `N7` share one texture region and one draw call. No
colour is baked into the glyphs.

**Colours in use:**

| Role | Colour |
|---|---|
| HUD label | `N4` |
| HUD value, menu entry | `N7` |
| Menu entry, disabled | `N3` |
| Menu entry, selected | `W4` |
| Warning, destructive confirmation | `W3` |

**Text over the playfield should carry a shadow** — one pixel of `N0` at offset `+1, +1`, drawn as
a second pass before the glyph. Over the HUD plates it should not: the plate is already `N2` and the
shadow only muddies the letter. The rule is about what is behind the text, not about which font it
is.

**Not built.** No renderer draws a second pass, and nothing in the MVP puts text over the playfield,
so the case has not arisen. Stated as a rule for whoever first does, rather than as a description of
the code — it read as the latter until 26/08/2026.

**No kerning, no ligatures, no letter-spacing tricks.** Position is `x + index * advance`, an
integer, always.

## Layout consequences

Because both advances are fixed, every string's width is known before it is drawn:

| Font | Width of `n` characters |
|---|---|
| `font-mini` | `n * 6` px |
| `font-title` | `n * 8` px |

The widest usable line inside a HUD column is 106 px, which is **17 characters** of `font-mini` or
**13** of `font-title`. Any label that does not fit gets shortened at design time; there is no
ellipsis and no wrapping in the HUD. Menus, which have the whole 480 px width, do wrap — at word
boundaries, on 10 px lines.

The score uses `font-title`, seven digits, zero-padded and right-aligned: `0012500`. Padding is the
arcade convention and it also means the field never changes width, so nothing next to it moves.

## Licensing

Both fonts are drawn for this project, so they are covered by the repository's own licence and
nothing has to be recorded in the external-asset register of
`../planning/07-references-and-asset-constraints.md`. That register exists for the case where an
external font is used, and this decision is what keeps that case from arising.
