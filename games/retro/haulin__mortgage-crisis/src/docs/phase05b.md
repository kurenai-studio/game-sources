# Phase 05b — Turn loop + discard down to 7

Phase 05b completes the “real” turn loop framing around the existing rules engine, and introduces the first **prompt-mode** flow that will later be reused for debt/payment and response windows.

## What Phase 05b implements

### Deterministic deck reshuffle when drawing

When drawing \(N\) cards, if the deck runs out but discard has cards, we:

- move **discard → deck**
- shuffle deterministically (seeded RNG)
- continue drawing until we’ve drawn \(N\) (or both piles are empty)

This keeps future “draw/reveal mid-turn” mechanics viable without special cases.

### End turn when hand is over 7 → discardDown prompt

Pressing **End** when your hand is too large no longer hard-fails; instead it enters a rules-owned prompt:

- Rules enter a **discard-down prompt** owned by the engine (prompt has an actor and tracks progress)
- UI switches into a prompt-focused mode (hand-only navigation)
- `A` discards the highlighted hand card
- once hand \(<= 7\), the engine automatically completes the pending end-turn (passes the turn + starts the next player’s turn)

Cancel behavior:

- `B` cancels **only before any discard** has happened in that prompt instance
- after at least one discard, `B` gives negative feedback and does not cancel

### Prompt-owned toasts (stacked)

We replaced the one-off “feedback message” toast with a stacked toast queue:

- `view.toasts[]` supports multiple timed and persistent toasts
- the discardDown prompt shows a minimal persistent banner:
  - `Too many cards. Discard N`

To keep centering predictable, toast text is rendered in **fixed-width** mode.

### QoL targeting improvements

- If a menu action (e.g. Place/Build/Rent) has **exactly 1** destination, the UI auto-applies it (skips the extra targeting step).
- For **hold‑A targeting**, we add **Source** as a destination so you can cycle back and drop onto the source to cancel.
  - During hold-targeting, the grabbed card is hidden in its source slot so you don’t see “two copies” on screen; it appears only as the preview at the current destination.
- Menu-driven targeting uses the **same Source destination + hidden source card** behavior as hold-targeting (so targeting is visually consistent regardless of how you entered it).
- **Early grab**: while holding `A`, tapping a D-pad direction enters targeting immediately, and the nudge **does not change** which card is being grabbed.
- Banking preview no longer overlaps the current bank top card:
  - when banking is previewed, the existing bank stack shifts left by one stack-stride so the preview can occupy the rightmost “new top” slot.
- While in **menu mode**, hovering an action shows a destination preview **only when there is exactly 1 real destination** (to keep the UI from getting noisy).

## Tests

- Command/prompt tests cover discard-down behavior and deterministic reshuffles.
- UI/control tests cover prompt navigation/cancel rules and targeting cancellation via Source.

## Definition of done

- `npm test` passes
- `npm run build` regenerates `game.js` (not stale vs `src/`)
- In TIC-80 Render mode:
  - End turn with hand > 7 enters discardDown prompt
  - Prompt shows a minimal “Too many cards. Discard N” banner
  - Hold‑A targeting can cycle back to Source; dropping onto Source cancels cleanly

