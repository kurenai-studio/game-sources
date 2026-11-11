# Phase 04 — UI-owned state machine (controller UX, bounded)

Phase 03b/03c established a solid renderer + dev harness, but navigation and selection were still renderer-owned and debug-first.
This phase converts Render mode into a **controller UX** driven by a **UI-owned view state machine**, while intentionally staying bounded to the **currently implemented rules commands**.

## Scope (bounded)

Phase 04 implements controller UX for these existing engine commands only:
- `endTurn`
- `bank`
- `playProp` (Place property / Wild)
- `playHouse` (Build House)

Deferred (future phases / later phases):
- Rent / Sly Deal / Just Say No
- debt/payment + received-property placement
- wild replace-window (implemented later in Phase 10)

## What Phase 04 implements

### Controls layer (`MC.controls`)

Render mode input is now injected (testable) rather than polled inside the renderer:
- D-pad navigation with **repeat** (delay/period configurable)
- `A` tap vs `A` hold+move detection:
  - **Tap A** → context menu
  - **Hold A + move** (or fallback hold threshold) → targeting (“grab”)
- `X` inspect hold with a short delay (~100ms)

All tunables live in `MC.config.controls`.

### UI-owned view state machine (`MC.ui`)

Render mode now has explicit UI modes:
- `browse`
- `menu` (center-panel context menu)
- `targeting` (place/build targeting with preview + ghosts)

Key UX behaviors:
- **Inspect**: hold `X` to show card/widget details in the center panel; D-pad navigation continues while held.
- **Menu** (tap `A` on a P0 hand card): shows `Place` / `Build` / `Bank` depending on the card and legality.
- **Targeting**:
  - shows **ghost outlines** (green) for all legal destinations
  - selected destination shows a **preview card** rendered into the destination stack with highlight
  - default destination prefers **existing sets** (then New Set); `Left/Right` cycles with wrap-around
  - Wilds: `Up/Down` toggles active color while targeting
  - confirm: `A` (menu-targeting) or **release `A`** (hold-targeting); `B` cancels
  - banking shows a preview-in-stack at the **bank destination** (hand-row bank stack)

### Directional navigation polish (screen-space)

- Navigation is **screen-space directional** (not row-index stepping), using cone scoring + axis-wrap fallback.
- Left/Right additionally **prefers staying in the same row** when a same-row target exists in that direction (prevents surprising cross-row jumps when center row has valid deck/discard/button targets).
- Per-axis tuning knobs:
  - `MC.config.ui.navConeKLeftRight`
  - `MC.config.ui.navConeKUpDown`

### Readability + feedback

- Illegal-action message is a **screen-top toast** with:
  - black background
  - border
  - red “X”
  - readable text
- Selection feedback remains blink-based (red highlight blink), with the message appearing on repeated attempts.

### Plays indicator (core HUD)

- The “3 plays per turn” counter is shown as an always-visible **3‑pip indicator**:
  - green `o` = remaining plays
  - red `o` = used plays

### End-turn “nudge”

When it’s P0’s turn and `playsLeft <= 0`:
- The End button gets a **positive recommendation cue** (green).
- The cursor is **snapped once** to End on the transition `playsLeft > 0 → 0` (browse-only), so the player can just press `A`.

### Debug hint placement + Phase label

- `Y:Mode` is treated as a dev hint and placed near the debug button strip (only when debug buttons are visible).
- The **“Phase 04”** label is shown above that hint for consistent screenshots.

### Config hygiene / avoid runtime fallbacks

- Prefer validating required `MC.config.*` knobs in tests over runtime “default to …” fallbacks in the cartridge.
- Config sanity tests assert existence/shape of key UI/control knobs.

### Numeric coercion cleanup (UI/render)

- Removed unnecessary bitwise coercion (`|0`) from UI and most render logic.
- Kept coercion localized to TIC-80 draw-call boundaries (e.g. `rectSafe`, `sprSafe`, `printSafe`) and deterministic engine/RNG hotspots.

### Renderer is display-only (`MC.render`)

The renderer no longer owns navigation/cameras or reads controller input.
It draws purely from:
- `state` (game state)
- `view` (UI view state)
- `computed` row models produced by the UI layer (so the renderer stays display-only)

Notable behavior change:
- The old always-visible center “big preview” is removed; details are shown via **Inspect** or menu/targeting overlays.

### Debug harness wiring

Render mode loop now runs:
`poll controls → UI step → apply intent → compute models → draw`

Center-row action widgets:
- `End` (always)
- Debug-only (gated by `MC.config.debug.enabled`): `Step`, `Reset`, `Next`

## Tests

- Render tests lock key invariants (selection layering, targeting ghosts/previews, etc.).
- UI/control tests cover injected input handling and the view-state-machine behavior.

## Definition of Done

- `npm test` passes
- `npm run build` regenerates `game.js` (not stale vs `src/`)
- In TIC-80 Render mode:
  - D-pad navigates rows/items with repeat
  - Tap `A` opens menu on P0 hand cards
  - Hold+move `A` enters targeting; destinations show ghosts + preview; release `A` commits
  - Hold `X` shows Inspect details
  - Center row shows End (+ debug buttons when enabled)

