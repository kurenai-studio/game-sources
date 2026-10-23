# Independent Test Expectations

Selected random-play, save, geometry, and fault-test families.

Bounded independently reviewed source packet for publication; no whole-claim certification. Source main. Phase 4 is closed, with five documented limits (D66 and D71 in DECISIONS.md). This is source and literal-data comparison, not a new game execution, reproduction, defect confirmation, certification or complete test-universe review.

## What this adds

The existing Phase 3 random-play relation is retained, not repeated as a new result. This packet separates assertion strength in four important families and checks the hard-coded geometry expectations against the adopted fixed table without importing production geometry. It names remaining comparisons rather than treating a test title, successful run or production validator as its own oracle.

## Random play

Source: test/gameManager.test.js:800-830, test/helpers.js:13-42 and75-90. Existing Phase 3 method support already records these bounds and its limitations.

| Assertion | Expected-value source | What it establishes if the named test passes | Missing relation |
| --- | --- | --- | --- |
| Delta in 0,100,300,500,800 | Literal set consistent with SCO-1 for zero or one clearing event | Membership for the observed driver-step delta | Exact clear count/order; multiple callback delivery may combine events inside one driver step |
| Level floor(score/1000)+1 | Literal SCO-2 formula | Relation of exposed score/level at sampled checkpoints | Full adopted unbounded score domain, all histories or all rounding behavior |
| Board 20x10, queue 3 | PCE-1 and PLY-8 literal dimensions/count | Exposed outer sizes | Sparse cells, cell validity, queue element validity and full R1 |
| Current and ghost fits | Production Tetromino.fits | Internal consistency with that predicate | Independent geometry/collision classification |
| Ghost row >= current row | Literal order relation | Ghost not above current at sampled checkpoints | Exact lowest independently valid landing position |
| Empty fault array | Literal empty result plus production reporting/monitor path | No recorded faults in these bounded runs | Every invariant or every semantic transition; reporting-path completeness |
| More than 100 game overs | Test-chosen seed/bound threshold | Bounded test progress condition | Requirement-wide seed distribution or random-play universal claim |

The same seededRandom(2024) closure supplies action choices and factory draws across rounds. Changing consumption in the factory changes later stimuli. This is a reproducible procedure with fixed source, not an implementation-independent action sequence. newGame dispatches production New Game and uses production memory storage. Fake advance removes the due callback before delivery and may deliver several callbacks per assertion checkpoint. Paired Pause/Resume hides the intermediate paused boundary. Physical events, Continue, all storage cuts and native timing are outside this test.

The historical tests26.log named-pass claim in Phase3 is not newly authenticated by this packet. The exact prior3,738-lock trace remains separate and unrecovered. A fresh native CI success is not substituted for its missing seed/harness/log.

## Serialization and saved fixtures

Source: test/session.test.js:15-80,145-185; public/game/session.js:30-41; fixture README.

- validSave uses production New Game, Hold, movement and serializeSession, plus direct board and score injection. Its name is not an independent B16-good certificate. The round-trip assertions compare board/current/queue/held to their production originals, while1300 and false are literal selected values. This detects some encode/decode mismatches but cannot detect a field jointly omitted by serializer and parser or certify the history that produced it.
- Bag assertions compare parsed fields to the same production factory bag. They witness retained sequence in selected fixtures, not an independent seven-kind dealing history. Fixture assertions written for the old save format are historical; see [the current bag assertions](phase-4-unit-expectations.md#bags-uniqueness-kinds-and-exact-order-are-different-claims).
- Malformed-input tests apply named local corruptions to that same generated baseline, then expect null. Board dimensions, missing fields and selected coordinate limits have independent criteria, but each case still needs its applicability/validity premise checked. Saved inputs use [R1 B16's stored-score ceiling](phase-1-r1-decision.md), distinct from B11's in-session whole-nonnegative domain. Rejecting a saved score above that ceiling is not the earlier unbounded-domain objection. Divisibility by 100 remains a separate applicability question.
- Released-format fixture comparisons are historical compatibility assertions, not an independent proof that captured values satisfy R1/B16. V34 retains its schema and missing original seed/action limits; capture authenticity is not upgraded.
- The round trip omits explicit saved lowest-row/reset-count expectations. The existing separate new-save history-loss finding remains separate; no new defect is inferred here.

Remaining: a claim-linked completeness/validity procedure for each accepted payload and independently good prior-save history, including only the applicable recorded legacy defaults, not another serializer/parser self-comparison.

## Geometry and kicks

Source: test/tetromino.test.js:10-32 and210-237, helper shapeStrings, adopted docs/sources/2-srs_table.txt. The literal color-to-kind association is explicit: cyanI, yellowO, purpleT, greenS, redZ, blueJ, orangeL.

Static extraction of SRS_SHAPES and comparison of X-cell coordinates to the adopted table found equality for 25 meaningful test entries: six four-state kinds and O state0. The adopted image/table has four duplicate O entries, while R1 B2 and PCE-4 define one valid O state. There is no new four-state O claim. The companion `phase-4-geometry-literal-comparison.json` records each literal and table coordinate set. No production module or test was executed. This establishes current numeric agreement with that table, not historical independence of the person who wrote the literals, fidelity of the table to its image, rotation behavior or full PCE-2.

shapeStrings only maps truthy entries to X and others to dots. The data assertion can detect changed truth occupancy, but does not classify arbitrary shape-element values independently. Four-block counts add a separate literal condition.

Kick literals are separately hard-coded clockwise SRS offsets, converted by (row,column)=(-y,x). The adopted fixed geometry reference explicitly excludes wall kicks. Hard coding is structural separation from the production table, not proof of independently sourced test-author values. Current later V55 records, rather than the older G2 missing-oracle label, describe an independently selected standard SRS extract excluding the Arika variant and bounded 48-row metadata / 550 ordinal visitor comparisons. Those records supply a separate audit expected-value relation; they do not retroactively prove how the permanent-test author obtained the literals. No new kick choice is proposed or represented as pending here.

V55's selected expected-source data, harness, result and review bytes were not recovered from the checked surviving archive and transferred evidence holdings. The current correspondence record's V53/V55 identity table is empty. Its narrative summary is not a substitute for those bytes. Until recovered and compared, this packet does not claim that the permanent-test literals have freshly been checked against that extract. The reported ordinal visitor method uses a declared fits stand-in, not independent real-board collision classification or all rotation/history compositions. Counterclockwise fallback tests have selected explicit outcomes, not exhaustive source/sequence proof.

Remaining: recover the actual V55 expected-source bytes and compare the permanent test's direction/order literals and selected fallback fixture against that existing relation. Preserve test-author historical provenance as a different question. Do not substitute production constants or a returned fits value for the expected source.

## Safety and fault composition

Source: test/safety.test.js:27-38,41-108 and250-257; D22T1/D23U2 and retained scope decisions.

assertSafeStop checks literal gameOver, zero fake outstanding timers, null two engine handles, one observed callback and equality of fault arrays. These are meaningful selected route witnesses. Equality to the same reporter records does not establish a separate player-visible notice. D22T1 requires notice and test signal together; the console-default test's literal log string/call count alone is not player notice. Existing display/fault records retain their own scope, and this packet does not classify a new defect.

The named last-good-save test first creates its supposed good save through production Pause, captures the bytes, injects a factory exception and compares retained bytes/flag, then Continues. This tests byte preservation and selected restoration, but not independent prior-good B16/S6 content/history. The comment good save does not establish that premise. Successful fake cancellation does not cover failed cancellation U3, provider retain-then-throw or native lifecycle. Later reporter-failure tests cover selected compositions, not every notice/signal/storage/timer combination.

Remaining: per-route cut and property ledger, distinguishing fault-only S3 from failed-save S5 and confirmed-New-Game S2. Existing serialization failure disposition is already Confirmed by its reviewed conditional source method; ordinary native serialization causes remain Not Established and no correction permission follows.

## Next work

1. Reconcile the complete important-test selection, including generated and browser families, against the eight-family Phase4 ledger. A source-registration count is not the test universe or a completion criterion.
2. Recover available expected-value provenance and execution receipts for selected families; record actual missing originals separately.
3. Complete writer/route/failure applicability and independent-good-save premises, not another navigation list.
4. Publication still requires independent exact-head review and checks; content review does not certify any property. No permanent tests, production, model or CI change is proposed.

## Exact source identities

Current selected source bindings live once in `phase-4-selected-source-manifest.json`. Rebinding does not recover or verify the October 8 engine register attachment. Historical records are evidence, not execution authority.
