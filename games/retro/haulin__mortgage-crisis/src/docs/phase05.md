# Phase 05 — Inspect overlay + tiny render polish

This phase focuses on **readability and iteration speed**: make Inspect useful (bigger, clearer, non-accidental), improve the center HUD ergonomics, and upgrade card copy so the game is understandable without relying on future icons/large cards.

## What Phase 05 implements

### Inspect overlay becomes a real panel (with config-driven geometry)

- Inspect (`hold X`) now uses a single **screen-space backing panel** with **panel-driven anchors** (preview + title + description).
- The panel bounds and internal padding are **explicit render config knobs** so we can tune quickly.
- The panel fill color is configurable via a render style knob.
- Description text uses **small font** (`smallfont=true`) for density.
- Deck/Discard and the center button strip remain visible; the panel intentionally occupies most of the center area.

### Center buttons remain available during Inspect

Previously, the center button strip was hidden while Inspect was held. This made it impossible to inspect button help text.

Phase 05 changes the center-row model so **buttons are only hidden during Menu/Targeting**, not during Inspect.

### “Value” line is generated (not hand-authored)

Inspect descriptions automatically include:

- `Value: $X`

…derived from `bankValue` (money/actions/house) or `propertyPayValue` (properties/wilds). This keeps card copy consistent and avoids duplicating values across `name/desc`.

### Rule-note system (gated by config)

We add a tiny rule-note mechanism for short constraints/notes that should appear in Inspect:

- `MC.RuleNote.*` enum IDs
- `def.ruleNotes: [...]` on card defs
- `MC.ruleNoteTextById[id] = "..."`
- `MC.config.rules.enabledRuleNotes = [...]`

Important: `enabledRuleNotes` is **not empty** in MVP1 builds because **Sly Deal’s constraint** (“not from full set”) is an MVP1 rule.

### Deck/Discard pile count digits “stick out”

Deck/Discard count digits are shifted by **(+1,+1)** via config knobs (`pileCountDx/Dy`) so the count reads as “outside” the card face, not part of its art.

### Card copy upgrade (all current MVP1 cards)

All current `CARD_DEFS` entries have updated `name`/`desc` text with:

- clearer 1v1 wording (“opponent”)
- properties/wilds include required set size + rent tables in text
- action/house copy upgraded (while keeping Phase 07+ gameplay still deferred)

## Tests

- Config sanity tests validate required knobs are present (and rule-note gating isn’t accidentally empty in MVP builds).
- UI/control tests include a regression check that the center buttons remain present during Inspect.

## Definition of Done

- `npm test` passes
- `npm run build` regenerates `game.js` (not stale vs `src/`)
- In TIC-80 Render mode:
  - Holding `X` shows a clear Inspect panel (small-font description)
  - Deck/Discard and the button strip remain visible/selectable during Inspect
  - Deck/Discard counts look visually “offset” from the card face

