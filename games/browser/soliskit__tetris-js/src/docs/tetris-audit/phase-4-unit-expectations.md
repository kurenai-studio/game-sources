# Unit-Test Answers

Selected board, bag, input, transition, and process assertions.

The unit tests contain useful literal answers for board size, movement, score, timing and input actions. They also compare some results with values built by the same game code. Those comparisons can catch a changed result, but they cannot prove that a shared assumption is right. This review adds the remaining selected unit families to the expectation ledger. It does not run the game or tests, confirm a defect, certify a property or close Phase 4.

The file named `test/model.test.js` tests production position, board and action helpers. It is not the separately frozen O8 reference model and does not provide model/implementation differential evidence. The frozen model revisions and the later correspondence records retain their own scope and history.

## What is selected, and why

This unit selects assertions that supply answers for board/piece admission, bag/queue history, input timing and state, legal clears, saved effects and process protection. They bear directly on the Phase 4 state, writer, route, protection and independent-expectation families. The earlier `phase-4-selected-independent-expectations.md` already covers random play, serialization, fixed geometry/kick literals and selected safe-stop assertions; the two browser documents cover selected game and outer-layer expectations.

The tracked test-source families are model helpers, factory, tetromino, game/manager, session, safety, controller, server/static files and traceability, plus game/app/safety/touch browser files. Naming these files defines navigation coverage, not completeness of claim review or runtime registration. Generated test declarations need their own local data domains. No test title or requirement tag is a substitute for inspecting its assertions. Remaining assertion-specific applicability and history are named below rather than discarded as unimportant.

## Board helpers and independent geometry

`test/model.test.js:7-46` uses literal row/column pairs, 20 rows, 10 columns, empty-cell values, action/mode lists and frozen-object checks. These are structurally separate from production helper definitions. The below assertion obtains its expected result through production position(), so the literal position test is a separate dependency, not an automatic independent expected object. The cellAt checks compare references to declared board entries and literal undefined at selected out-of-bounds coordinates.

The board test's row.every and flat().every checks do not independently reject sparse collections: those operations skip missing entries. Its two neighboring-cell mutation checks can detect those particular aliases, not every possible alias among all 200 cells. This is an assertion-strength limit, not a newly observed malformed production board or a new finding.

A separate scratch calculation, with no production import, translated the adopted O offsets `(0,0),(0,1),(1,0),(1,1)` onto the declared 20 x 10 board. At positions `(0,0)` and `(18,8)` all cells fit. At `(0,-1)`, `(0,9)`, `(19,0)` and `(-1,0)`, a cell leaves the board. With a block at `(10,5)`, O at `(9,4)` overlaps and O at `(8,4)` rests above it. These are the independent answers for `tetromino.test.js:69-80`. On an empty board the O top row can fall to 18; above a block at `(15,5)` it can fall to 13, matching the literals in lines 92-102. This computes expected sets only; it does not execute the production predicate or claim a new passing comparison.

The manager's selected O wall bounds 0 and 8, blocked movement at column 4 against `(1,6)`, and ghost top rows 18 and 13 follow the same fixed geometry under the declared fixture. Wider pieces, sparse boards, arbitrary representations, all rotations and all writer routes remain separate. Tests that finally call production fits to assert the result fits do not independently prove that predicate, even when their explicit position or orientation assertion adds a useful answer.

`Tetromino.copy()` initially shares the original position object, rotation arrays and kick data by reference. The copy test replaces `copy.position`; it does not mutate the shared position in place. Its unchanged-original assertion therefore shows replacement isolation, not in-place isolation. See [Piece Bag Checks](phase-3-bag-supplement.md) for supplied-bag consumption by reference and the external-mutation boundary.

## Bags: uniqueness, kinds and exact order are different claims

`factory.test.js` expects seven pieces, 50 selected bags of seven distinct colors, repeatability under seed 7, a difference under seed 8, fresh object identities and selected reset behavior. The cardinalities and reference inequalities are independent relations. The set of expected colors comes from production PieceColors, so set membership depends on that kind/token binding; seven distinct output colors alone is not an independently literal list of the seven kinds.

The constant-zero shuffle test builds expected order from production allPieces and repeats the descending swap-with-zero algorithm. That can check injected randomness and a selected ordering, but it shares algorithm and initial-order assumptions. PCE-5 requires a shuffled seven-kind bag, not that particular Fisher-Yates implementation or exact order. The near-one test compares with production allPieces order. Neither exact-order check is a full fairness, entropy or distribution proof.

`gameManager.test.js` checks 20 seeds across two new games, seven distinct current colors, saved bag length 2 and saved sequence reuse. Its missing-bag Continue case now asserts game over, an unavailable save and the new game's unchanged existing bag, not an empty bag. These are selected queue/refill and refusal assertions, not every refusal cut or all legal dealing histories. The saved sequence comes from the production factory being tested; its reuse is a preservation relation, not an independent shuffle oracle. The fixedFactory and sequenceFactory helpers use production pieces and chosen repeated kinds; their histories are not certified seven-bag histories merely because the pieces fit.

The earlier Phase 3 bag supplement describes an independently justified kind/complement relation and finite choice-tuple enumeration. That is a separate audit expected-value relation, not proof of the permanent test author's source. This review neither reruns nor authenticates its old raw receipt. Aligned bag segments, all sliding windows, external bag mutation and full saved history remain different scopes.

## Input actions and fake time

`inputController.test.js` records actions in a stand-in manager, captures window listeners and animation callbacks, supplies gamepad objects, and uses Node mock timers. The literal keyboard action map, defaultPrevented flags, action sequences, selected held-direction returns and 167/33/50 ms boundary counts have expectations outside the production controller. Imported action constants supply token identity, not the rule that a key should cause that action.

The manager stand-in does not change mode when handleAction is recorded. Most tests therefore establish controller dispatch, not the resulting game transition. A few separately instantiate the real manager; their fixtures and engine effects need their own premises. The gamepad helper constructs standard button indices and axes. Its source declares them as standard mapping, but no device descriptor or platform trace is inspected here; action literals do not authenticate physical transport.

The test tick helper advances Node mocks in at most 10 ms increments because its comment describes a mock scheduling limitation. Exact count assertions near 49/50 and166/167 are meaningful selected fake-time answers. They are not measurements of native elapsed time, all callback ordering or provider start/cancel failures. The controller's paused-repeat stop checks observe no further action and undefined soft-drop handle after ticking; they do not assert U4's safety checkpoint at each firing or prove no outstanding firing existed immediately on Pause. The already recorded paused-repeat and resume findings remain separate.

The gamepad-read failure test at lines 555-569 injects one getGamepads throw, expects one console report and one queued next frame, then supplies a pad and expects Drop on that later callback. This witnesses a selected signal and positive continuation if executed. It does not inspect U2's player notice or every later callback. No new defect classification follows from the omission in this test.

## Manager transitions, score and persistence

Generated line-clear cases at `gameManager.test.js:283-291` use the independent SCO-1 literals 100/300/500/800 and expect `4 - lines` remaining I blocks. The fixed-table vertical I occupies four cells in column9, so filling the declared bottom rows' other nine columns makes the selected row count and residual arithmetic independent. Helpers construct the fixture with production actions and `#fff` filled cells; that color is not one of the adopted seven kinds. The test is not a legal R1-kind-valued history or a complete valid-save witness. The later legal-source records retain their separate predicates and limits.

The survivor-row assertions name literal moved cells and colors after one clear, and the nonadjacent-clear test preserves its one-gap row. These are selected ordering answers, not every imported full-row state or all alias/failure prefixes. Score1000/level2/interval0.68 and score10000/interval0.5 follow SCO-2/PLY-2 formulas for those chosen values. Native firing time and the full unbounded numeric domain are not supplied by those finite literals.

Lock-delay tests use fake time and literal 499/500,400+100,15-reset and16th-move boundaries. Those assertions are separate from production constants. Some landing setup stops when production isOnSurface returns true, and some cases directly inject count/lowest/position/board values. Each needs its own validity and history relation. The published count15 Resume and lowest-history dispositions remain governing; a passing permanent test cannot override B9.2. Exact deadlines, requested delay and native timing are different observations.

The exhausted-reset landing test injects count 15 and lowest 18 into an O piece at anchor row 17. Its occupied rows are 17-18; falling to anchor 18 reaches occupied row 19. Under [R1 B9.2](phase-1-r1-decision.md), that new low resets the count to zero. The assertion of immediate locking therefore needs an independently admitted history that makes its expected result applicable. The test's comment about an earlier turn does not supply that history. This is an oracle/applicability limit, not an executed defect.

The new-low rotation test injects lowest 15 into a T already occupying row 16, then accepts a final reset count of at most 1. B9.2 requires zero when a new low is reached. Its kicked-anchor assertion does not establish independently admitted prior history or complete ordered kick selection. [AUDIT F20](../../DECISIONS.md) remains the finding home.

Getter assertions using tolerance `1e-9` compare seconds. [S10's requested-delay tolerance](phase-1-r2-r5-decision.md) is `1e-9` milliseconds. Fake delivered-time steps such as 699/1 or 600/100 do not themselves establish that requested-value comparison.

State-guard snapshots serialize mode, score, current, held, queue and board. They do not include reset count, lowest history, bag, control resources, cached eligibility, saved bytes or all reports. Equality after each selected action is valuable because opposing actions cannot hide one another, but it is not the adopted full frame. Hold compares saved original piece/queue colors plus a literal false availability; this is selected swap/preservation behavior, not every R5 content representation or failure cut.

The storage-key test wraps setItem and compares the observed key set with three explicit names. It establishes the selected successful-action key set, not every route, ordering, value or foreign-actor history. Eligibility caching counts only reads of the eligibility key; it is not a count of all storage reads. Pause/Continue and last-good tests still compare production-generated content and omit independently justified complete B16 history. The existing persistence-effect ledger carries actual-cut and prior-good-content gaps.

## Hostile cases must use the adopted domain

The safety violations and session corruptions generate concrete inputs and literal reasons/null answers. Wrong dimensions, missing fields, fractional coordinates and overlap have independently describable local invalidity. Expected rejection of score150 because it is not divisible by100 does not follow R1 B11's whole-nonnegative domain. Neither does rejecting a full row solely because ordinary play clears rows: B15 separates snapshot validity from legal history. Safe-integer rejection must not impose a numeric format limit that R1 excludes. These are previously retained domain questions, not fresh executions or new findings in this review.

A locally invalid corruption does not require every untouched baseline field to be valid in order to justify rejection. Conversely, a supposed successful or last-good baseline does require its complete applicability premise. Produced parser null, production invariant reasons, an empty fault list or four displayed cells cannot certify that premise.

## Process tests check records, not semantic adequacy

`traceability.test.js` extracts single source lines matching test(, then requirement tags. Its literal empty missing/unknown-tag results check that textual relation. It does not expand generated declarations into runtime tests or inspect whether each assertion proves its tag. The title "every requirement is verified" is broader than that tag-set assertion. The >100 and >=40 thresholds are test-chosen sanity bounds, not a Phase 4 important-test selection rule.

Config-string and regular-expression checks establish selected coverage thresholds, browser projects, typecheck settings and mutation command wiring. They are not actual coverage, browser execution, typecheck or mutation results. Coverage remains structurally different from independent correctness; passing process checks grants no test-removal authority.

`staticFiles.test.js` compares selected literal manifest/viewport values, file existence, PNG header sizes, source-import/preload graphs and the production APP_SHELL list. The graph traversal handles its declared import syntax, not every dynamic reference; source agreement is not a browser request trace. PNG dimensions do not inspect icon pixels. The server tests expect explicit status/MIME pairs and missing-path404 responses on a spawned local server; these are independent selected protocol answers, not every path/subfolder/hosted deployment or security claim. No server or image inspection is performed here.

## Continuity and remaining work

The selected source assertions are reconciled against current main. This review reads source and computes small coordinate/arithmetic expected answers without importing or executing the game, tests or frozen models. No bytes of production, tests, models, CI or requirements are changed. Model freeze/history, important-test completeness, generated corruption applicability, complete frame/adapters and per-writer failure cuts remain separate gates.

Source identities are recorded in `phase-4-selected-source-manifest.json`. Criteria: blueprint4.6; REQUIREMENTS.md; R1 B2/B3/B5/B9/B11/B15/B16; D23 U2/U4; D34 E2/E3. Earlier source narratives are evidence leads, not execution or effect permission.
