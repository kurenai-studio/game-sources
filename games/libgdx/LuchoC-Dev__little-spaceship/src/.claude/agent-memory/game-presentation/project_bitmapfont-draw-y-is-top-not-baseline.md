---
name: bitmapfont-draw-y-is-top-not-baseline
description: BitmapFont.draw's y parameter is already the top of the text box, not a baseline or bottom-left corner — reusing the same y-down-to-y-up rect helper for text double-subtracts the height
metadata:
  type: project
---

`BitmapFontCache.addText`'s javadoc (checked against `gdx-1.14.2-sources.jar`,
`com/badlogic/gdx/graphics/g2d/BitmapFontCache.java`) is explicit: the `y` parameter is
"the y position for the top of most capital letters in the font (the cap height)". So
`BitmapFont.draw(batch, text, x, y)` already treats `y` as a top-edge coordinate in y-up space —
the same thing `04-hud-layout.md`'s `y_gdx = 270 - y_down - height` formula computes for a
`batch.draw(texture, x, y, w, h)` rect, whose `y` is the **bottom-left** corner.

Using that same helper for text — `yGdx(yDown, font.getCapHeight())` — subtracts the cap height a
second time and pushes the text down by roughly one line, landing labels on the row below their
intended slot. This was `game/.../adapter/render/HudRenderer.java`'s actual LIVES/BOMBS/POWER
overlap bug: the geometry constants (slot x/y, pitch, boss bar) all matched
`docs/design/04-hud-layout.md` exactly, only the three text-drawing methods (`label`, `value`,
`title`) were wrong.

Fix: for text, convert with a **separate** helper that only flips the axis
(`LOGICAL_HEIGHT - yDown`), no height subtraction. Keep the rect helper (`yGdx(yDown, height)`)
for anything drawn with `batch.draw`. Do not merge the two into one function — they take the same
two inputs but mean something different, and that similarity is exactly what caused the bug (see
[[project_windows-desktop-screenshot-verification]] for how this was confirmed on screen, not just
read from the source).
