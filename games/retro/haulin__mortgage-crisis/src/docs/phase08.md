# Phase 08 — Actions + responses (Sly Deal + Just Say No)

This phase adds the first “response windows” to MVP1:

- **Sly Deal**: steal an opponent property **not from a complete set**.
- **Just Say No** (JSN): single-layer only, playable as a reaction (does not consume plays).

## What shipped

### Sly Deal (targeting + resolution)

- Sly Deal can be played from hand via:
  - tap‑A menu entry:
    - `Sly Deal...` when multiple targets exist (enters targeting)
    - `Sly Deal → <Color>` when exactly one target exists (auto-applies on select)
  - hold‑A immediate targeting
- Target selection uses the existing targeting mode, but with **cursor-moving targeting**:
  - L/R cycles Sly targets ordered by **screen‑space X** (left→right)
  - cursor jumps onto the currently selected opponent property (so there’s only one “real” highlight)
  - a `Source` option exists at the end of the cycle and returns selection to the Sly card
- Resolution:
  - Sly Deal card is discarded and consumes a play
  - If the defender has JSN in hand, the defender gets a `respondAction` prompt (Pass vs JSN)
  - Otherwise, the steal resolves immediately
  - Stolen properties go into the existing `placeReceived` prompt (recipient faux-turn placement)

08b follow-up UX:

- If there are **no** legal Sly targets, hold‑A on Sly enters hold‑A **hold-chain** targeting starting at **Bank** (so Bank remains available).

### Just Say No (single-layer)

- JSN is legal only in explicit response windows:
  - **Sly Deal**: via `respondAction` prompt
  - **Rent**: integrated into `payDebt` when the debt is action-sourced
- JSN is **only legal before any payment** is made in `payDebt`:
  - `prompt.srcAction` must exist
  - `prompt.buf.length === 0`

## Prompt model updates

- `payDebt` prompts can now carry optional `srcAction` metadata:
  - `{ kind, fromP, actionUid }`
- New prompt kind: `respondAction`:
  - Carries `srcAction` (what is being responded to)
  - Carries `target { uid, loc }` so UI can mark the forced target

## UI behaviors

- **No “two cursors” look**: Sly targeting uses cursor-moving selection instead of a second “preview highlight”.
- **Target marker for respondAction**: when the cursor is away from the forced target, the target is shown with a **ghost outline** (and the ghost is suppressed when the cursor is on the target).
- Prompt toasts teach response windows:
  - `Rent: Pay $N or Just Say No` (only when JSN is actually available)
  - `Sly Deal: <Color> or Just Say No`

## Focus rules

- Entering `respondAction` prompt auto-focuses the forced target so the player immediately sees what is at stake.

## Config knobs

- `MC.config.ui.slyShowTargetGhosts` (default false): show ghost outlines for *non-selected* Sly targets during Sly targeting.
- `MC.config.ai.biasPlayJustSayNoK` (default 8): soft-bias the AI toward playing JSN when legal.

## Scenarios

- Updated `debtHouseFirst` to include action-sourced debt metadata + JSN for testing `payDebt(JSN)` gating.
- Updated `moveStress` so Sly has legal targets.
- Added `slyJSN` scenario to start directly in a `respondAction` prompt. (It also includes a separate single-target Sly-in-hand setup for menu-hover/auto-apply repro after the prompt.)

