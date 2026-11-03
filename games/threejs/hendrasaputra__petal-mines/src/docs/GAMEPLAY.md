# Playing Petal

## Playable through Step 3

- **Classic:** eight same-floor neighbors.
- **Layered:** two or three independent floors. Clear every safe tile on every floor; one mine ends the attempt.
- **Connected:** local numbers plus ↑ / ↓ clues. Each arrow counts the clipped 3×3 footprint on the immediately adjacent floor, including the aligned tile and excluding its own floor. Top/bottom boundaries never generate an arrow pointing outside the stack.
- The clue neighborhood is shared by counting, zero flood and chording. Wrong flags can make a chord expose a mine. Flagging all mines alone does not win.
- **Volume remains a future chapter.** Adaptive pixelation, expanded campaign content and final release polish are later milestones.

## Campaign and fairness

Seven curated levels introduce local rules, independent floors, upward clues, downward clues and mixed cross-floor deductions. Complete each level to unlock the next. Chapters can be revisited once unlocked. A level's safe openings are already revealed; its seed, coordinates and generator version reproduce its exact layout on Retry.

Every shipped level is solved in tests using visible clues, flags and the displayed mine count per floor. The solver uses basic constraints and overlapping subsets; ambiguity stops the solver rather than causing a guess. Connected tests require deductions involving the direction being taught, including both directions in the mixed lesson. “One logical hint” applies one deduction and identifies its source clue when available; floor-total deductions need no source tile.

Free play has new random seeds, fixed safe openings, 1–3 floors for Classic/Layered, and three floors for Connected. Random free play may require guesses and is labeled accordingly. Retry preserves the layout; New puzzle changes the seed. Pre-v2 saves migrate, and legacy arbitrary-first-click boards recover their original layout for Retry where reproducible.

## Controls

Tap to reveal, hold or right-click to flag. Explicit Reveal / Flag / Inspect modes avoid relying on long press. Tap a revealed clue to inspect it. **Double-click or double-tap a revealed number** to open its unflagged neighbors when the neighboring flag count matches the clue. You can also choose **Open unflagged neighbors** in the inspector. Wrong flags can expose a mine. In Connected, arrow clues chord their indicated floor footprint. **View target floor** selects a vertical clue's destination; outlines and HTML labels identify its exact target cells.

Drag to rotate, pinch/scroll to zoom, or reset the camera. Focus isolates a floor. Exploded shows the stack with inactive floors dimmed; only the selected floor accepts tile input.

Expand **Keyboard & accessible board** for semantic grid controls: arrows move; Enter/Space uses the selected action; F flags; I inspects; C chords. E changes view; 1–3 selects floors. Instructions pause active-play timing, as does a hidden tab. No animation requires motion tolerance.

## Persistence

The v2 local save includes the puzzle, elapsed time, selected floor/view/action, campaign level and completed IDs. It migrates v1 saves, rejects unsupported versions and inconsistent boards, and normalizes metadata. Storage failure leaves the game playable and displays a notice. Retry resets the current attempt while retaining campaign progress. The UI verifies a saved campaign configuration against the shipped level before awarding completion.
