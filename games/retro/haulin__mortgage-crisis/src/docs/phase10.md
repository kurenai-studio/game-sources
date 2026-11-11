# Phase 10 — Wild replace-window (optional Wild reposition)

Phase 10 adds the **Wild replace-window**: after placing a property into a set, the rules may offer an **optional** prompt to reposition **exactly one eligible Wild** out of that same set (without consuming an extra play).

This phase also includes follow-up UX polish so the interaction behaves consistently with existing targeting conventions (notably **Source-cancel** and **no double-render** rules).

## What shipped

### New prompt: replace-window

- New prompt kind: `replaceWindow`
- Trigger points:
  - after a **property play from hand** into a set
  - after each **received-property placement** (during the recipient placement prompt), with resume back into the remaining received placements
- Win interaction:
  - if the triggering placement produces a win, the replace-window is **skipped**

### Eligibility (bounded, MVP-friendly)

Replace-window is offered only when:

- the set that was just played into contains a Wild **other than the just-played card**, and
- removing exactly one Wild would leave the **source set still complete** (after removal, set size ≥ required size)

### New commands / moves

- `skipReplaceWindow`: decline the optional prompt and continue (or resume the interrupted placement prompt)
- `moveWild`: move a Wild from the source set to:
  - another matching-color set, or
  - a new set
  - with an explicit chosen color assignment (Wild “counts as” the chosen destination color)

Notes:

- `moveWild` does **not** consume an additional play (it is part of the same play that triggered the replace-window).
- Destination ordering in targeting is screen-space **left→right**, with **New set last**, and **Source** (cancel) last of all.

### UI / controls

Prompt mode:

- Toast: **“Move a Wild? A:move B:skip”**
- Cursor auto-focuses an eligible Wild in the source set.
- **A** enters targeting to select destination and Wild color.
- **B** skips the prompt.

Targeting consistency improvements:

- `moveWild` targeting includes a **Source** destination so cancel-by-cycling-to-source works like other targeting modes.
- Global targeting rule: the source card is hidden while targeting to avoid a “two copies” look, **except** when **Source** is the selected destination (the real source card is shown again with normal highlight). This avoids double-render at the source slot.

### Renderer support

- Targeting source-hiding now supports table-stack sources (set properties), so `moveWild` preview does not visually duplicate the Wild at both source and destination.

### AI

- Added a soft-bias policy for `moveWild`, gated by a tuning knob:
  - prefer moves that **complete a set**, then prefer positive rent delta
- New config knob: `MC.config.ai.biasMoveWildK`

### Scenarios + tests

- Added a dedicated `replaceWindow` scenario to exercise:
  - overfill-complete source sets
  - eligible destination sets + New set
- Added/expanded tests covering:
  - prompt creation, skip, and move semantics
  - nesting inside recipient placement with correct resume
  - Source-cancel behavior and “real source visible when Source selected”
  - win-skip behavior

