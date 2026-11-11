# Phase 19 — Demo polish + targeting/overlay refactor

Phase 19 started as “demo polish”, but quickly converged on a deeper theme: **targeting and overlay policy** had become too duplicated and too easy to break.

This phase focuses on:

- fixing real UX bugs (especially around mouse targeting and prompt flows)
- refactoring the targeting/overlay pipeline so future changes are safer

## What shipped

### More consistent targeting titles + help (mouse vs controller)

- While mouse-dragging and **not snapped** to a destination, the targeting title reads as a **drop action** (so it doesn’t look like “cancel onto a target”).
- Wording is normalized so release-to-apply actions read consistently (less “Drop/Confirm” mismatch across flows).
- Mouse-click targeting help text is formatted in a stable layout (readable, not crammed).

### Wild single-destination nuance is scoped to the right context

We kept the original UX intent:
when placing a Wild from a **hand menu** and there’s only one real destination, starting on “source” avoids implying the game already chose a target.

But we fixed the leak:
that nuance should **not** apply to prompt-driven flows (like placing received properties), where it can suppress affordances and make back/cancel semantics confusing.

### Prompt flows: predictable buttons + better error messages

- Prompt-specific “debug buttons” remain usable in the prompts where they’re needed for testing.
- When a forced-response prompt forbids a generic action (like ending the turn), the error text explains what the player must do next (instead of a generic “no moves” message).

### Replace-window “snap” stability

Controller-driven “snap back” actions are now truly stable (no one-frame flash followed by selection preservation undoing it). Any snap that’s meant to stick also resynchronizes the view state immediately.

### Cursor-mode targeting (Sly Deal): mouse drag semantics

Cursor-mode targeting has stronger “selected” affordances than preview-mode targeting. During mouse drag:

- cursor highlight does not “stick” to targets just because the pointer passed over them
- preview emphasis is shown only when snapped
- preview is rendered above the destination stack for readability

## Refactors (readability + duplication reduction)

- Targeting text/policy is made more data-driven and centralized (less scattered conditional logic).
- Row-model / overlay computation was split into a more dedicated structure so overlay passes are easier to reason about and modify.
- Build-order hygiene was preserved while reorganizing UI modules (keep deterministic concatenation consistent with the numeric prefix convention).

## Tests updated / added

- Added/expanded regression coverage around:
  - targeting title/help text
  - Wild placement nuance across contexts
  - prompt messaging and button availability
  - cursor-mode mouse drag behavior

## Definition of done

- `npm test` passes
- `npm run build` regenerates `game.js` (not stale vs `src/`)
