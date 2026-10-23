# Browser-Test Answers

Selected scores, pictures, controls, and layout assertions, with their limits.

The selected browser tests check useful things a player can see: scores, buttons, saved-board pictures and some layout. They do not, on their own, prove that a saved game is valid or that every game state and failure is handled correctly. This review separates the tests' independent expected answers from the parts built with the same game code they test. Phase 4 is closed, with five documented limits (D66 and D71 in DECISIONS.md). No test or game code was changed or executed for this review.

## Selected claims and expected answers

| Test claim | Independent expected answer | What the assertion actually reads | Limit |
| --- | --- | --- | --- |
| Only locked blocks are drawn at game over | The declared stack has 18 x 9 cells, one extra cell and four distinct O cells: 167 total | Number of opaque board-cell center samples; literal Game Over text; empty previews | Conditional on fixture construction and pixel projection; not every pixel, timers, notice or valid-save history |
| Clearing one line updates score | The declared vertical I fills the one missing bottom cell, so one row clears and adds 100 under SCO-1 | Score/High Score text and zero remaining blue samples | Injected declared board, not a legal-play history; no 2-4 clear, exact stored-number domain or save-goodness proof |
| Pause can be continued after reload | Selected before/after board picture should agree; the page should show Continue then Resume | DOM button/hint text and sampled canvas cells | Production Pause/serialization and Continue share a format; jointly missing reset count/lowest can pass this picture test |
| Another tab's high score becomes visible | The declared stored value 4200 should be displayed | Literal DOM text | Does not test game-earned high scores, every numeric representation or same-session withdrawal history |
| Screen fits without scrolling | Selected DOM boxes stay within declared viewport; board aspect ratio is about 2 | Document extents, button/preview bounds and board box ratio | Finite layout checks, not a picture inspection, all viewports, physical safe-area or accessibility proof |

These independent arithmetic and literal answers are meaningful. A test is not wholly circular just because its setup uses production code. But a narrow literal assertion does not give independence to every unasserted field or to the setup's historical provenance.

## Engine-fault notice assertions

`e2e/engine-fault-notice.spec.js` declares 15 source cases: two fault timings, six failed-recovery notice-retention cases, two successful-recovery clearing cases, four independent-attempt cases and one repeated-fault case. This count is a source inventory, not a run receipt.

Its page-route adapter appends `window.testGame = gameManager` to expose the private manager only in the test. The fault helper calls the real guard with a synthetic injected exception; selected cases also replace report, drawing, recovery or storage providers. These are selected injected failures, not native browser failures or proof of every fault route.

The assertions check visible `#gameOverMessage` text, its `aria-hidden="true"` attribute, `#announcer` text and `role="status"`, and selected console-error text. Manager state, fault reasons and timer handles are read through the test-only exposure. The two timing cases capture a screenshot, but do not assert its pixels. DOM and aria assertions do not establish that a screen reader spoke the message.

Successful Continue setup still uses the production-built savedGame fixture. See [AUDIT F25 and F30](../../DECISIONS.md) for finding status.

## Sources and continuity

The six-source archive comparison was made before PR175 changed touch.spec. It established byte equality for app.spec, fixtures, game.spec, helpers, safety.spec and the older touch.spec at that comparison, not equality to current main. The other five source files remain unchanged in this read-only reconciliation. Source continuity does not establish an original execution or independent review.

The retained per-registration source commentary was read as earlier analysis. Its claims were checked against game.spec and helpers for the selected rows above, not accepted as measurement receipts. The earlier commentary's 22 declarations are navigation, not an important-test selection criterion, actual browser count or completion result. The present selection targets the persistence/expected-value dependency and explicit arithmetic assertions, not every browser family.

## Fixture and observation adapters

`e2e/helpers.js` savedGame constructs a real GameManager with a fixed built-in shape, scheduler returning handle0 without outstanding-callback accounting, direct board/position/score writes, and production Pause. It then exports payload/eligibility/high-score values. The resulting fixture is not independently certified B16-good, and fixed repeated kinds do not establish a seven-bag history. The setup's successful calls do not repair missing count/lowest denotation.

boardCells samples one center per 20 x 10 logical cells using canvas.width / 10. It returns a color only when alpha > 200; cellsOf filters by color. This is a declared pixel projection, not an independent authoritative-state decoder. Ghost outlines are expected to leave centers empty. canvasHasDrawing reads any alpha > 200 anywhere, which is a different observable from shape, position or correctness. PieceColors and BOARD_COLOR come from the production factory; fixed hex/color assumptions remain separate from adopted kind geometry.

The 167 result is independent finite-set arithmetic on the declared coordinates and fixed O shape, not the production filledCount output. The O at box(0,0) occupies (0,0),(0,1),(1,0),(1,1); none overlaps the extra(1,4) or the rows2-19 stack. The vertical I at box(0,7), rotation1 occupies column9 by the fixed table. At its bottom landing the cells are rows16-19,column9; only row19 completes against the nine declared blue bottom cells. After removing that row, three I blocks remain and the next current appears; zero blue is the selected assertion. Exact hard-drop/state/save compositions remain distinct.

The picture round trip has no expected reset-count, lowest-history, bag sequence or actual eligibility-effect ledger. Equal board pictures can accompany the already recorded count/history information loss. A passing picture comparison must not supply F20's independent-good-prior-content premise.

## Remaining evidence

The other browser families require their own claim-linked expected values and adapter premises. Physical-input, touch/mouse substitution, wake-lock, drawing failures, cache identity and native lifecycle remain separate. An original archive or explicit executed result is needed for historical execution claims; no new run is inferred from source equality. Final important-test coverage and phase exit remain undecided by this selected packet.

Source hashes: game.spec be4ea55b4bc789721a8287a7056bac4d2c5e67972297a23c54ed09f85e4315ff; helpers 7c9e9233b81cb27ec8062d8b8ca8abec9bf305c85e3e313fd3be56408d2b64f2; fixtures ae232242ff43bae1cff86e5f5b554d0adaa69979d84f8780dbbc42cd1f28194a. Selected game.spec anchors: 68-90,352-364,366-398,400-407,419-488. No production, permanent test, model, CI, requirement or publication mutation belongs to this draft.
