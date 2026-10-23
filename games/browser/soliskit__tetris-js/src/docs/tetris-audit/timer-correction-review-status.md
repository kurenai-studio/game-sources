# Timer and Player-Notice Proposals

Proposed fixes, their review status, and the evidence still needed.

These proposals aim to stop timers safely, prevent held controls from restarting after Resume, and show players when something fails. None of these candidates is implemented by PR171 or PR172, which are separate and narrower; their status is in [AUDIT F25](../../DECISIONS.md). The timer-stop pair is separate from the input and notice candidates; no package is implementation-ready merely because its patch applies or parses.

## Candidate groups

1. Fault/checkpoint containment and reliable cleanup: use the engine boundary for repeat callbacks and selected registered handlers; detach handles before cancellation, preserve the original fault and first cleanup error, attempt remaining cleanup independently, invalidate retained callbacks by generation. Failed-clear intervals may keep firing inertly; that is not cancellation or disappearance of the resource. Keyboard/release and sampled input-dispatch exceptions become engine faults, including controller-dispatch bugs. Gamepad connection polling setup and automatic RAF recovery remain separate gaps.
2. Synchronous exit stop: stop gameplay repeats when a checked operation begins playing and ends nonplaying, before its completed checkpoint. Do not repeatedly re-fault on paused no-op polls. Nested guards, throwing cleanup while already paused and independent resource attempts need tests.
3. Resume suppression: physical keyboard/stick/d-pad tokens in observed press order, own release/repress eligibility, pad-originated Resume reusing the successful in-flight sample, fresh read for other origins and finally cleanup. Mixed-device order, sampled simultaneous edges, dialog release versus token creation, reconnect mapping and observation limits need review. Blur reset is not established by INP-2's repeat-stop clause. Failed fresh-read block-all-pad is a proposed policy, not D34 E2.
4. Player notices: independent contained DOM, test-signal and console attempts with distinct engine/drawing/controller categories. Notice lifetime, per-category latching and same-checkpoint clearing are proposals, not existing requirement wording. A signal alone does not establish player-visible reporting; DOM/provider cuts, repeated faults and continuation need independent evidence and actual pixels.

## Exact retained candidate identities

These SHA-256 values identify the retained candidate text, not the current production source.

| Candidate | SHA-256 |
|---|---|
| Fault boundary | d3580b0067f3ea386818baa1d0596d988804c1d28f8f160e990a4a6fec933fcc |
| Exit stop | 582e6d372440ad8ac6913fecc6fbd96910672cde8d94e8cb6dab26a994d7b26b |
| Resume suppression | 6b2c8db0f23b8c38d28d8d56f15316850e6f467b2f2503712a7dbeff2ef54b04 |
| Player notices | 24ea612e07b8c007fda02f70410b8522d5e2d50d1c9e08ca26d9f8241c96c2e0 |

These are candidate provenance, not executable-model acceptance, production changes or a claim that every test is complete. Earlier independent review reported scratch sequential application and syntax checks only; revised exact-diff review and remaining decisions still govern readiness. No game, harness, permanent test or production execution was performed for this status record.

## Evidence and remaining approval gates

Keep distinct the paused-firing checkpoint omission, ordinary Pause retained-repeat resource, Resume rearm/movement, registration refusal, disconnect cancellation refusal and retain-then-throw orphan cases. Source arguments and qualified historical/simulated reproductions do not become native measurements by being grouped here. Reconcile existing evidence before any missing pre-fix run; freeze criteria, dependency cuts, expected results and regression/collateral matrix before execution under its original scope.

Regression work must cover many retained ticks and a later New Game, all cleanup combinations including thrown undefined, playing-to-nonplaying transitions, aliases and mixed-device survivors, successful in-flight sample reuse, dialog paths, observed releases and selected blur/read-failure policy, notice-provider failure/overlap/lifetime and phone/desktop pixels. Existing mocks need approved interface updates; full coverage and mutation gates cannot be weakened to make proposals pass. No smallest-change or Apple-design claim is established by these candidates.

Other correction families remain separate: persistence withdrawal/failure order, saved-history meaning, count-15 Resume, stored-high-score domain, cache ownership and outer-layer reporting/recovery. Each requires its own minimal correction, failing-before/passing-after regression, collateral review and applicable owner approval. This record does not close Phase 4, a property or the correction backlog.
