# Step 1–3 validation · 3 November 2026

Scope: harden Classic/Layered, establish reproducible no-guess campaign puzzles, and implement Connected. Volume and final release polish remain outside this milestone. `INITIAL_IDEAS.md` is preserved unchanged.

## Automated checks

`npm test`: **59 tests across five files pass**.

| Suite | Coverage |
| --- | --- |
| Engine | Seed determinism; mine totals; safe first reveals; flags; flood fill; correct/incorrect chording; terminal states; floor independence; exact fixed/legacy retries; local/vertical neighborhood fixtures; clipped boundaries; shared directional flood/chord targets; malformed saves; generator versions; 40-seed Connected invariant sweep |
| Solver | Single-clue and overlapping-subset deductions; forced mine/safe actions; ambiguity stops without guessing; contradictions; no mutation; hidden mine getters throw if consulted during deduction |
| Campaign | Every shipped fixed opening is reproducible, resumable and solver-completable; required upward/downward source use; mixed level stalls when either arrow direction is removed |
| Storage | v1 migration, v2 roundtrip, corruption, unsupported versions, normalized metadata, deduplicated known level IDs |
| Gestures | Tap; hold once; right-click; cancel; background tap; drag and drag-back; interrupted pinch; no post-pinch reveal; coincident pinch coordinates |

`npm run build`: TypeScript checking and Vite production build pass. Approximately 134 kB gzip of JavaScript; Vite reports a non-blocking uncompressed chunk-size warning for the Three.js bundle.

## Production browser run

The built `dist/` was served with Vite preview at `http://localhost:4173/`. All levels were completed using only the player-facing **One logical hint** button; unlocks and Next level were exercised in order. No developer-state injection or hidden mine reads were used by the browser test.

| Level | Hint actions | Safe cells cleared |
| --- | ---: | ---: |
| First steps | 4 | 22/22 |
| Clear thinking | 9 | 31/31 |
| Another perspective | 10 | 44/44 |
| Three little worlds | 29 | 93/93 |
| Look up | 14 | 44/44 |
| Look down | 22 | 44/44 |
| Hidden connections | 22 | 66/66 |

The mixed level's solver trace uses both upward and downward clues. Each campaign test requires a nontrivial opening (not an automatic win). These proofs establish solvability under the supported deduction rules, not subjective difficulty or tutorial quality.

## Additional browser checks

- An intentional mine hit showed loss; Retry restored the exact visible opening. Flag and campaign progress survived reload.
- Explicit chord control increased cleared cells from 37/44 to 38/44 with correctly matched target flags.
- An upward interior clue highlighted nine cells on the adjacent floor; a downward edge clue highlighted six cells, including the aligned coordinate and excluding its own floor.
- Active floor, exploded view and Inspect mode survived reload together.
- Hold for 650ms changed mines left from 9 to 8 once, with cleared cells unchanged. Dragging the board and tapping an inactive floor left cleared cells unchanged.
- Keyboard flagging/navigation and HTML board states were exercised. The HTML grid has row/cell semantics and direction-specific labels.
- Responsive checks at 320px, 390px and 768px showed document width equal to viewport width. Focus and exploded views were inspected; inactive layers remain dimmed and cannot intercept active-floor picking.
- Rules dialog kept the active-play timer unchanged while open.
- Free-play Retry retained the displayed seed; New puzzle changed it.
- No browser console warnings/errors in the final production campaign run.

A transient browser approval timeout interrupted one development rerun. Retrying the same action succeeded; the complete production run subsequently passed.

## Limits and handoff

Physical iOS/Android multitouch, screen-reader audio output, cross-browser GPU compatibility and long-session performance were not available in this environment. Pinch interruption is covered by pure gesture tests; physical touch feel is for the user's game-testing pass.

Random free play may require guessing. Hints assume player flags are correct. The curated campaign's no-guess guarantee applies to its fixed openings and supported visible-information deductions. Only seven introductory levels are shipped; this is the Step-3 milestone, not the proposed complete 32-level campaign.

Local saves are browser/origin-specific and can be cleared by the browser. The tested preview has all seven levels unlocked from the validation run so Connected is immediately available. Choose Retry to replay any selected level.

A [production screenshot](docs/connected-preview.jpg) records an inspected upward clue in exploded view. Camera fit was also checked after reset; wheel/pinch zoom intentionally permits closer, cropped views.

## Double-click / double-tap chording update

The suite now has **71 passing tests**. Twelve additional cases cover matching revealed-tile taps, distinct touch pointer IDs, timing and tile/floor boundaries, hidden-first-reveal protection, drag/pinch/hold/right-click/cancel interruptions, and Classic/Connected chord integration. The existing chord engine still requires matching target flags and preserves incorrect-flag loss behavior.

Browser checks on the production build confirmed a 3D double-click and an HTML-grid double-click each increased cleared tiles from 17/22 to 18/22 with a correctly flagged neighbor. Without flags, double-clicking left cleared tiles at 17/22 and displayed the flag-count requirement. The HTML-grid check also covered opening a previously closed inspector without moving the number away from the second click. Physical-device double tapping remains for hardware testing; simulated pointer sequences cover that input path.
