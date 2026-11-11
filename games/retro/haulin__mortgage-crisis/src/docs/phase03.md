# Phase 03 — Rendering Baseline + 5-row Layout

Phase 03 introduces a **visual renderer** for Mortgage Crisis that can draw the locked 5-row layout and allow controller navigation + selection highlights.

This phase is still **debug-first** and remains **rules-driven**:

- Rendering is **read-only** (no direct state mutation from UI).
- The only state changes are via existing rules engine commands when stepping/debugging.
- We keep the Phase 02 text debug harness as a fallback, and add a Phase 03 visual harness that renders the same `MC.debug.state`.

## Decisions locked (from interview)

### Harness / mode switching

- `Y` cycles **Boot → DebugText → Render → Boot**.
- Render screen uses the same backing state as debug: `MC.debug.state`.

### Controls (Render screen)

- **D-pad**: move selection cursor (wraps).
- `A`: **step** one random legal move (same behavior as debug step).
- `B`: next scenario.
- `X`: reset scenario (keep existing Phase 02 mapping).
- `Y`: cycle mode (Boot/DebugText/Render).
- Controls hint is rendered as a **single-line overlay** (tweakable via render config knobs).

### Seating + opponent mirroring

- Screen anchoring is stable: **P0 bottom** (Rows 4–5), **P1 top** (Rows 1–2).
- Opponent rows are **mirrored**:
  - Mirrored horizontal ordering (right-to-left).
  - Mirrored fan direction for stacks (peeks “outward” consistently).
- Opponent cards are **fully flipped 180°** (positions + sprite rotation), not just glyph-rotated-in-place.

### Cursor model

- All 5 rows are selectable:
  - Row 1: opponent hand backs (preview reveals actual card in center panel for debugging)
  - Row 2: opponent table sets/stacks
  - Row 3: center widgets (selectable: **Deck**, **Discard**, **P0 bank**, **P1 bank**)
  - Row 4: player table sets/stacks
  - Row 5: player hand
- Left/Right uses a **flat item walk** across visible cards (including within fanned stacks).
- Wrap behavior: **wrap Left/Right and Up/Down**.
- Initial selection: **Row 5 (player hand), index 0**.
- Per-row horizontal camera: **keep selected in view** with **12px margins**.
- In table stacks, a `House` attached to a set (`set.houseUid`) is treated as an **extra selectable card** at the top of that stack (drawn as a normal mini-card in the fan order).
- Up/Down row transitions choose the destination item by **nearest x-center** (not by raw index).

### Namespacing (new Phase 03 code only)

To avoid adding more top-level `MC.*` symbols, Phase 03 code lives under:

- `MC.render` (namespace created once in the prelude)

The harness calls a small render entry point, but most helpers/constants stay under `MC.render.*`.

### Config centralization (what actually shipped)

To make pixel tweaks fast, Phase 03 moved tweakable render knobs into configuration:

- `MC.Pal.*`: named Sweetie-16 palette indices (e.g. `MC.Pal.White=12`, `MC.Pal.Yellow=4`)
- `MC.config.render`: render-related knobs (layout/geometry, styling/colors, sprite IDs/mappings)

The renderer reads these values and **fails loudly** if they’re missing (load order is deterministic by design).

## Layout geometry (locked + tweakable constants)

### Screen

- Usable area: **240×136** (`MC.config.screenW`, `MC.config.screenH`)

### 5-row vertical bands (exact)

We lock exact row bands (0-based y=0..135):

- Row 1 (opponent hand backs): **12px** → y=0..11
- Row 2 (opponent table): **27px** → y=12..38
- Row 3 (center panel): **43px** → y=39..81
- Row 4 (player table): **27px** → y=82..108
- Row 5 (player hand): **27px** → y=109..135

Notes:

- Rows 2/4/5 are 27px so a 25px card face + 1px highlight above/below can fit cleanly.
- No additional inter-row gap pixels are reserved; visual separation comes from the highlight/card styling itself.
- Row 1 intentionally shows only a **partial** card-back slice; selection highlight may extend beyond the visible slice (matching Session 01 behavior).
- Row 1 shows the **bottom slice** of opponent hand backs (cards extend upward off-screen), and is still rendered through the same **full 180° card flip** pipeline for correctness.

### Mini-card face (common)

- Card face size: **17×25** pixels, including a **1px white border**.
  - Card-local coordinates are 0-based: border pixels are x=0..16, y=0..24.
- Selection highlight is drawn **outside** the card face border (1px “glow” / border), and selected items are re-drawn last so the highlight is always on top.

Implementation note:

- In Phase 03, the border and interior colors are controlled via `MC.config.render.cfg.colCardBorder` and `MC.config.render.cfg.colCardInterior`. If they are equal (e.g. both `MC.Pal.White`), the border becomes intentionally subtle.

### Stacks (fan / peek)

Stacks are horizontal fanned piles with a 1px separator “shadow bar” on the overlap boundary:

- Stack stride: **8px** between successive card faces.
- Shadow bar placement depends on **fan direction**:
  - Fan right (`fanDir=+1`): **1px black** at `xFace-1`
  - Fan left (`fanDir=-1`): **1px black** at `xFace+faceW`
  - This covers the underlying face’s 8th column, yielding **7px visible** peek.
- Gap between stacks: **2px**.

## Mini-card templates (MVP specs for Phase 03)

We will keep these as constants/anchors so the layout is easy to tweak once rendered.

### Digit glyph rendering (critical)

- Digit placement uses an **inner 3×5 glyph** (that’s what all anchors refer to).
- Glyph sprite tiles may include a **1px white border** for readability (so the inner 3×5 lives at **(1,1)** inside the 8×8 tile).
  - Renderer draws the tile at **(-1,-1)** relative to the inner glyph top-left, so the visible digit pixels do **not** move.
  - Use **`colorkey=15`** for both digit glyphs and icons.
- To keep a digit’s **inner-glyph top-left** anchored when rotated 180° (TIC `spr rotate=2`), the renderer offsets the sprite draw position accordingly (with tile=8, inset=(1,1), inner=(3,5) this is **x-4, y-2** for rotate=2).

### Property cards (dual-color wild)

Top half anchors (0-based, within the 17×25 face):

- Value digit glyph at **(1,1)**
- Color bar rect spans **x=5..15**, **y=1..5** (equivalent to `rect(5,1,11,5, color)`).
- Rent row starts at **(1,7)**.

Bottom half for the second color is the **strict 180° transform** of the top-half layout (positions + glyph rotations).

### Property cards (fixed single-color)

- Draw the fixed-property template on the **top half only** (no mirrored bottom-half template for Phase 03).
- Opponent full-card flip still applies (so the top-half template ends up on the visually-correct side for the opponent).

### Money / Action / House cards

Common rules:

- Top-left is always the **card value** (money value or `bankValue`), drawn directly over the colored background (digit sprite provides its own outline).
- Background color is determined by the card’s **value** (actions/houses share the money palette mapping via `bankValue`).
- Center icon is a single **8×8** sprite at **(4,9)** inside the 17×25 card face.
- Dithering is deferred; Phase 03 can use flat fill colors.

Rent cards (special template):

- Rent action cards render with an **always-white interior**.
- They draw **2px-tall color bars** stacked from the **bottom upward** inside the 1px border.
  - Colors come from `rentAllowedColors` on the card def (bottom→top order).
  - `rent_any` (allowed colors = null) is treated as **4 bars** in order **Cyan, Black, Magenta, Orange** (bottom→top).

### Sprite IDs

- Sprite IDs are **not locked** yet.
- All IDs used by renderer must be defined as constants in one place (so remapping is trivial once the atlas is finalized).

### Integer coercion (`|0`) — keep it at the boundary

Phase 03 initially used `|0` pervasively to “force ints,” but that quickly becomes unreadable.

The policy we settled on:

- Renderer logic stays normal JavaScript numbers.
- Integer coercion happens only in the **TIC-80 API boundary wrappers** (e.g. `rectSafe`, `rectbSafe`, `sprSafe`, `printSafe`).
- RNG/rules code can still use `|0` / `>>>0` where 32-bit behavior matters.

This keeps determinism and TIC-80 API hygiene without turning every line into bitwise clutter.

## Testing approach (Phase 03)

Even though rendering is visual, we add lightweight tests:

- In Node tests, stub TIC-80 draw calls (`rect`, `rectb`, `line`, `spr`, etc.) to **record draw calls**.
- Write 2–4 small tests that assert key invariants:
  - Selected item is drawn last / highlight is drawn last.
  - Stack stride/shadow placement: next card face is +8px; shadow is at `xFace-1` for fan-right stacks and `xFace+faceW` for fan-left stacks.
  - 180° flip math places opponent glyphs at the expected flipped coordinates.
  - Anchors for dual-color property top-half match the locked coordinates above.

## Definition of Done

Phase 03 is done when:

- Render screen draws the locked **5-row layout** and is navigable via controller.
- Per-row horizontal camera behaves correctly with overflow (12px keep-in-view margins).
- Selection highlight works and selected middle-of-stack cards are brought to front visually.
- `Y` cycles Boot → DebugText → Render.
- `A` steps rules-driven state and the visual output updates accordingly.
- `npm test` passes (including new render draw-call tests).
- `npm run build` produces a valid `game.js`.

## Wrap-up (Phase 03 complete) — handoff for next session

### What shipped

- **Harness**: `Y` cycles **Boot → DebugText → Render**; Render draws the same `MC.debug.state`.
- **Renderer**: locked **5-row layout** (opponent hand backs, opponent table, center widgets, player table, player hand).
- **Navigation**:
  - All 5 rows selectable; Left/Right is a flat item walk; wrap all; Up/Down uses nearest-x.
  - Per-row horizontal camera with 12px margins, plus a clamp that forces `camX=0` when row content fits on screen.
- **Cards**:
  - Mini-cards at 17×25 with 1px border; digit glyphs/icons use sprites with `colorkey=15` and correct 180° anchoring.
  - **Money/action/house**: value digit over background + single 8×8 center icon.
  - **Rent cards**: white interior + stacked 2px bottom color bars (from `rentAllowedColors`; `rent_any` defaults to Cyan/Black/Magenta/Orange).
  - **Wild properties in sets**: render oriented by assigned set color (stored as `[uid, color]` in `set.props`), and show assignment in top-left status.
- **Stacks / banks**:
  - Properties + banks use a unified fanned-stack draw helper keyed by `fanDir`, which picks shadow side and draw order.
  - Bank stacks are rendered inside hand rows and are mirrored between players; player bank preserves **top-left value visibility** on covered bills.
- **Selection layering**:
  - Selected item is drawn last with highlight.
  - For stacked cards, the selected card is **cleanly on top** (we do not draw separator shadows over the selected card).
- **Tests**: draw-call recording tests cover key invariants (highlight ordering, shadow placement, rent bars, mirrored opponent stack shadow, bank stack behavior, camera no-scroll).
- **Build**: `npm test` and `npm run build` are green.

### Alignment notes / discrepancies to keep in mind

- `docs/plan.md` Phase 03 mentions a richer center panel (preview + prompts). The shipped Phase 03 center panel is intentionally minimal (widgets + debug overlays); richer UX is a good candidate for Phase 03b or Phase 04.
- Earlier wording implied stack shadows always at `xFace-1`; the shipped renderer uses **fanDir-dependent shadow placement** (documented above).

### Likely missing / Phase 03b candidates (optional polish)

- **Center preview**: large-card preview / description text, including opponent hand reveal in center when selecting row 1.
- **Center prompt UI**: structured prompt text (future Phase 04 will need it anyway for menus/prompts).
- **HUD polish**: decide on final controls hint style (single-line vs boxed) once center panel content grows.

### Next session checklist

- Decide whether to do a short **Phase 03b** (preview/prompt polish) or jump straight to **Phase 04 UI state machine**.
- If doing Phase 03b: implement center preview (selected card render + 1–2 lines of info) and add at least one draw-call assertion for it.
- If starting Phase 04: define the first prompt flow (e.g. `A` on hand card → context menu) and what minimal center-panel text UI is needed to support it.

