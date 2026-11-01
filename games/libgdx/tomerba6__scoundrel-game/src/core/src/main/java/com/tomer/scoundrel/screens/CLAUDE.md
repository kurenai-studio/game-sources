# Screens — the screen-specific rules

This is the screen-specific half of the root `CLAUDE.md` — its rendering rules, `PixelScreen`,
the palette and the sprite regions — kept here so it loads when a screen is opened rather than
in every session. It is just as binding. Section numbers (§2, §8, §10, §11) refer to the root
`HANDOFF.md`.

## PixelScreen

The five navigable screens extend **`PixelScreen`**, which owns the batch, viewport, surface,
backdrop, chrome and press gesture and whose `render` is **final** — it runs the
post-navigation guard before calling the subclass's `drawContent`, because drawing after a
screen has navigated (and disposed its own batch) kills the JVM rather than throwing. Override
the hooks (`advance`, `backdropLight`, `modal`, `escape`, `keyPressed`), never the frame.
`SpriteLab` stays outside it deliberately.

**`GameScreen` replaces the frame's input processor with its own `BoardInput`,** so nothing
`FrameInput` routes reaches the board unless `BoardInput` routes it too — and it has its own
modality (`endSummary != null || asking`), since `modal()` is only read by `FrameInput`. ESC
was missed this way, and a run could not be left until `BoardInput.keyDown` was added. When
`FrameInput` gains something, mirror it on the board. What ESC does there is `BoardEscape`.

Motion (deal-in, avoid sweep, per-card effects, HP pulses) and the atmosphere ship as
`BoardView` over `CardFlight` / `HpPulse` and the rest — `Choreographer` and `Motion` went with
the pixel conversion, so a `docs/ui.md` entry naming them describes what was replaced.

## Sound

- **A sound fires on its animation's beat, never when the move is applied.** `GameScreen` picks
  *what* from the move's events (`SfxChoice`) and hands it to `BoardView`, which holds it in a
  `PendingCues` until the beat `Beats` reads off the effect's own constants. Move an animation
  and its sound moves with it. A skip or a cut-in plays everything still pending at once, so
  every action sounds exactly once.
- **Menu buttons click on press**, as the plate sinks (`PixelScreen.pressAt`). Buttons pressed
  during a run are silent (`clicks()`), except the end panel's. The title's SOUND plate clicks
  on release instead, at its new level.
- Audio never takes the game down: every load and play is guarded, and a failure is silence plus
  one log line. The whole reference is the root's `docs/audio.md`.

## Palette and sprite regions

- **The palette has two tiers, and both are tested.** `Ramps` is the 80 and governs sprite
  pixels; `UiPalette` is the 32 colours drawn in code that are not on a ramp — the §11 chrome,
  the bottle, the cleave faces, the HUD tints — all sampled from the reference render, not
  invented. `UiPaletteTest` scans both declaration forms (`static final int … = 0x…` and
  `Color.valueOf("…")`) and fails on a colour in neither. A new colour goes in `UiPalette` with
  a comment saying what it draws.
- **Region names are the contract:** `creature_<value>_<name>_<suit>`, frames add
  `_idle_1`…`_idle_5`. Lowercase `[a-z0-9_]`, index last, so
  `atlas.findRegions(stem + "_idle")` returns the five in order. Value is zero-padded
  (`02`–`10`, `11`=J, `12`=Q, `13`=K, `14`=A).

## Rendering rules

- **`TextureFilter.Nearest`, integer scales only (1, 2, 3, 4), whole-pixel positions.** These are
  hand-placed pixels; a fractional scale or a sub-pixel offset invents colours outside the
  palette and makes the art shimmer. `Math.round` every computed position before drawing.
- **`PixelViewport(1280, 720)`** on every screen. Every number in `HANDOFF.md` is in that space;
  sprites draw at ×2 = 128px inside a 176×256 card. Do not re-derive the layout per window size.
  It fits like a `FitViewport` (it extends `Viewport` directly) but snaps the scale **down to a
  multiple of 0.5** and letterboxes the rest — a plain fit gives ×1.25 at 1600×900, which puts 2.5 screen pixels on each source pixel
  and makes the art crawl. Half-steps, not whole: 1920×1080 fits at exactly ×1.5, already clean
  at ×2 sprites, and integer snapping would letterbox away a third of it. The maths is the pure,
  unit-tested `PixelScale`; keep it there rather than in the GL class.
- **Idles run at 6 fps, effects at 12 fps**, and nothing tweens or rotates — every segment holds
  on a frame. A rotated pixel is a blurred pixel. Floor time through `Frames`
  (`at`/`atPeriod`/`snap`), never a local `1f / 12f`: it carries the epsilon a frame boundary
  needs, and multiplies by the rate so an hour-old clock has not drifted past it.
- **The barehanded stars are four bars, never a rotation** (§10). The diagonal arms are staircases
  of 8×8 blocks — exactly 45°, grid-aligned, no transform. A rotated rect is the worst thing you
  can do to a pixel sprite.
- **Every screen is in scope, not just the board** (§11) — title, new game, ledger, trophies,
  tutorial and run end all move onto the same grammar. They are assembled from five parts
  (frame, face, bevel, label, rule); learn those and the screens are assembly work.
- **Screen transitions are cuts.** One frame, old screen gone, new screen up. No fades, no hover
  glows, no panel shadows, no rounded corners anywhere.
- **The torchlit backdrop stays smooth, and that is now decided** — a soft glow, a continuous
  flicker and sub-pixel drifting embers behind flat-palette sprites. It is the one place that
  breaks the whole-pixel and quantised-timing rules, deliberately: light is not an object. Don't
  dither it, coarse-render it or round the embers to the grid.
- **Hurt and rim frames are generated in Java at load** from each base sprite (§8), not shipped.
  There are no death frames — the card dissolve covers it.
- **Silkscreen replaces IM Fell English and Alegreya Sans entirely**, at pixel-aligned sizes with
  no anti-aliasing. `Theme` loads the two Silkscreen TTFs and nothing else; the three vector
  faces and the Scene2D skin were deleted with the last of Scene2D.

The mock (`art-reference/Scoundrel - Sprite Directions.dc.html`) is the visual target: the board
at 1280×720, every effect in isolation, all 26 idle cycles, and all six screens. It opens in a
browser — ask the user to compare against it; you can't render it yourself.
