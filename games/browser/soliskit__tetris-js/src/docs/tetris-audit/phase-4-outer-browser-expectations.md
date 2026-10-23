# Offline, Touch, and Drawing Tests

What the selected browser assertions observe beyond the game engine.

The browser tests have useful expected answers for offline launches, touch input, drawing and the screen wake lock. Some answers are independent literals or geometry. Others read a limited part of the result through a fake browser feature or a helper that shares the game's assumptions. A passing test can support its stated observation without proving the whole requirement. Phase 4 is closed, with five documented limits (D66 and D71 in DECISIONS.md).

This source review adds the app, safety and touch families to the selected browser-expectation review. It does not run a test, confirm a new defect, certify a property or change code. The important-test selection is still incomplete; the unit and generated families need separate reconciliation.

## Useful independent answers

- Cache update tests use explicit page titles and module tags 1 and 2. The old page must keep tag 1 while the next launch uses tag 2. Those tags are chosen by the test rather than computed by the worker. They check the selected HTML and one module, not every resource's version.
- The touch test's two-turn T answer is the literal shape `(0,0),(0,1),(0,2),(1,1)`. It agrees with T state 2 in the adopted fixed geometry table. Normalizing position preserves this shape comparison. It does not prove every rotation, kick, pointer path or physical Safari tap.
- The blocked-drag fixture has 16 declared rows with four locked cells each: 64 cells. The ledge fixture has six such rows: 24 cells, although that test does not assert their count. These numbers come from the declared coordinates, not a production board-count method.
- A granted fake wake lock should be held while playing and released after Pause or game over. The explicit request, grant and held counts check the game's selected policy against an external fake ledger, not whether a physical screen stays awake.
- Paused drawing tests compare intercepted fill calls and animation-frame requests before and after a declared quiet interval. Equality is a meaningful relative answer. It does not cover every drawing method or storage read.

## Cache tests: tags are independent, completeness is not fully observed

`app.spec.js:115-173` stops a local server for offline reload and changes a copied page title for the next-launch test. The observed buttons, four opaque cell centers and titles support those selected outcomes. They do not measure "straight away", every file, all clock values or all launch interleavings.

`newestCachedPage`, at lines 136-147, filters the production version prefix, orders names with the same parseInt convention and returns the first cache with an HTML entry. That helper is not an independent test that a cache contains the whole shell. "Deploy 2" absent from this helper can coexist with unobserved partial entries elsewhere. The interrupted-download test at lines 213-248 removes one module and checks its request, title retention and later recovery. It does not enumerate every cached response or independently classify all caches as complete.

The delayed-script test at lines 253-297 provides a stronger selected version relation: the title and one module carry matching independent tags despite a newer cached title appearing before script loading. It still does not tag every resource, exercise pin expiry or clock jumps, corrupt pins, simultaneous downloads or foreign version-prefixed caches. The adopted K1/K2 clock scope remains separate.

The earlier-cache cleanup fixture creates `tetris` and `tetris-2` itself and expects them gone. The foreign-cache test creates `other-project` and reads only whether its name survives. The first is selected legacy cleanup evidence; the second is selected name retention, not byte retention. Neither answers the blueprint's distinct attack where a foreign project owns a name the worker deletes or a nonempty version-prefixed cache. Those existing attack tracks and dispositions are not replaced by these tests.

## Safety tests: a recovery sample is not the whole fault policy

`e2e/safety.spec.js:7-36` starts from production-generated savedGame, then uses malformed JSON, a missing queue or a declared overlap. The expected refusal and visible New Game are independent selected observations. The baseline's label `good` does not supply independent B16 history. The malformed JSON answer needs no good baseline; the missing-field and overlap cases have their own local reasons for rejection, not a certificate that every untouched field is valid.

The drawing-failure test at lines 39-60 throws on one Canvas fill, hard drops, then expects eight opaque cell centers and one matching console-error string. The console string is a separate test-visible signal, not U2's small player notice. A later eight-cell picture is bounded drawing continuation, not every future frame or the whole SAF-5 conjunction. Eight assumes the selected drop locks four cells without a clear or immediate game over, and the next current contributes four distinct visible cell centers. The test does not independently inspect those state premises.

The blocked-storage test at lines 62-78 replaces both reads and writes for every Storage object, starts a game, drops three times and expects 16 opaque centers, Pause/Resume labels and no collected errors. Sixteen has the same conditional sum: three four-cell locked pieces plus the current piece, with no clear, overlap or game over. Random factory draws and production setup remain part of the fixture. The selected result does not show all storage-failure cuts, save withdrawal, high-score effects, native provider refusal or independent prior-good content.

`trackErrors` listens for pageerror and console errors after listener registration. An empty array establishes no such collected events. It is not an independent check of every invariant or every player-visible notice.

## Touch tests: geometry, transport and history are different premises

`shapeOf` normalizes the sampled color-cell coordinates and sorts them. It checks a selected shape modulo translation; losing a cell or changing the relative coordinate set changes the normalized string; uniform translation does not. Simple "shape changed" assertions do not specify the correct next orientation. The two-turn T literal adds a particular expected orientation from the fixed table. Every saved touch fixture still uses production Pause/Continue and the fixed repeated-kind factory; no legal seven-bag history or complete save-goodness follows.

The sideways drag test starts the T at box column 3. Its state-0 occupied columns start at 3. A 2.6-cell drag is expected to move it three columns, then the reverse drag returns it to 3. This selected expectation reflects the half-cell threshold in INP-5. It does not enumerate exact boundary equality, all event partitions, reversal paths or saved history. The downward test accepts a minimum row of at least 5 after a 3.2-cell drag from row 2; the loose inequality permits additional gravity and is not an exact per-cell transition proof.

The O/locked-stack tests combine independent fixture coordinates with pixel edges and named color centers. The right-edge bound 6 follows from the obstacle beginning at column 6; the retained locked-cell count is 64. The wall reversal and ledge tests assert selected positions, not all blocked paths. A drag-outliving-its-piece test compares the new top piece before and after more drag input, allowing at most one gravity row. The time window, color grouping and injected history limit that witness.

`boardTouch` uses Chromium CDP touch events; on non-Chromium it substitutes mouse events. The source explicitly makes that substitution. The quick-tap tests run only in Chromium, while zoom tests replace visualViewport.scale and dispatch synthetic resize/gesture events. CSS, listener and literal shape observations are useful project-policy evidence. They are not physical Safari zoom, native touch transport or the four separately approved phone relations' execution receipts.

[AUDIT F28](../../DECISIONS.md) records the input-delivery limits of the six permanent 10-pixel boundary cases. The earlier touch supplement's strict-less-than comparison is historical; the adopted tap decision is not superseded.

The hold-box tap tests assert only that canvasHasDrawing returns true for heldPreview. They are "tapping the hold box holds the piece" and "a quick tap on the hold box right after one on the board still holds". The first uses locator.tap; the second uses touchscreen.tap and is Chromium-only. Their [helper observable](phase-4-selected-browser-expectations.md#fixture-and-observation-adapters) does not identify the held piece, replacement piece or count.

## Wake lock and drawing adapters

`fakeWakeLock` has grant, deferred grant, refuse and missing modes. Its sentinel marks itself released and emits one release event; counters expose requests, granted sentinels and unreleased sentinels. Literal count sequences check selected stale-grant, replacement and reacquisition policy without calling production wake-policy functions. They do not cover rejection of release, missing event delivery, all promise schedules, visibility changes or actual platform revocation. Physical screen sleep remains unobserved here.

Resize checks assert backing width equals rounded CSS width times density and four sampled centers. The density test replaces devicePixelRatio and dispatches a resolution-query event because its source reports an emulation limit. That comment is not an independent current-browser compatibility check. Display-P3 tests query contexts and pixels, with expected palette values imported from production. They check selected API/color relations, not independent perceptual gamut or physical iPhone vividness. The palette import's shared origin is distinct from the independent fixed geometry.

The installed-app test asks Chromium CDP for manifest/installability errors and skips other browsers. No installed icon, fullscreen UI or physical installation is observed. The whole-game test drives a bounded repeated key pattern, expects game over, some occupied centers and no collected errors. It is not the historical 3,738-lock trace or independent full transition correspondence.

## Source continuity and remaining gates

The earlier source comparison was made before PR175 changed touch.spec. Its statement that only the PR111 document differed belongs to that historical comparison, not current main. App.spec, safety.spec and helpers remain byte-equal to that source base; touch.spec changed in PR175. Source equality is not an execution receipt or a statement of test-author historical independence.

The selected family boundaries above come from the source assertions and their expected-value dependencies, not registration counts or coverage percentages. Complete important-test selection, model/implementation comparison where applicable, all writer/failure applicability, raw historical receipts and claim-specific property disposition remain. No native or physical gap is waived. No production, test, model, CI, requirement or repository-rule change is proposed.

SHA256 identities: app.spec `de90fc3ccff0d4160dcbde2fb5701d463952434eaef64e076999200c530d071f`; safety.spec `623aee55a4d968421f65efd2ffcb861d9f55802667e1450f18b92da0c0745fdf`; current touch.spec `be92f6a56a5bdd2452d7e59ce283c13ce6c66879a57592d7674e31350af7e2bb`; helpers `7c9e9233b81cb27ec8062d8b8ca8abec9bf305c85e3e313fd3be56408d2b64f2`. Criteria read: REQUIREMENTS.md; blueprint section 4.6 and 4.8; fixed `docs/sources/2-srs_table.txt`; U2 in `docs/phase-1-trust-and-timer-scope-decision.md`; K1/K2 in `docs/phase-1-clock-decision.md` (deleted, bytes in git history; `DECISIONS.md` row D29 governs). Historical author claims in comments remain attributed, not authenticated by this review.
