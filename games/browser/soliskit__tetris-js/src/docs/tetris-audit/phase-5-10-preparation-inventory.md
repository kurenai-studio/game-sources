# Later Audit Phases

What Phases 5 to 10 need before they can finish.

This register lists what each later phase needs in order to close and what each phase waits on. It is preparation only. Phase 4 is closed, with five documented limits (D66 and D71 in DECISIONS.md). Phases 5 to 10 wait on their written exit checks. The owner authorized automatic progression through Phase 10 when those checks pass. Separate approvals for reserved actions still apply; nothing here starts, certifies or approves them.

Candidate inventory for independent review. No execution, finding promotion or demotion, correction, permanent-test change, property certification, phase promotion or Phase 4 exit. Central matrix and DECISIONS.md rows are left to the coordinator.

## Sources read

Source identity is main. Checked current bytes at that commit:

| Source | Current SHA256 |
|---|---|
| `docs/audit-blueprint.txt` |  |
| `DECISIONS.md` |  |
| `docs/phase-4-domain-work-ledger.md` | 7b7bdecfc88fc46360292b7b6d9df5c391b8da085be4ce9157550dcadea8385c |
| `docs/timer-correction-review-status.md` | 55803d41baf9c381b7161d0e733c77ce8837502d5f62ed799f739bfe97b041e5 |

Also read: `docs/tetris-audit/phase-4-work-in-progress.md` (deleted October 17, see D76), `package.json`, `stryker.config.json`, `playwright.config.js`, the opening of `REQUIREMENTS.md`, and the workflows `.github/workflows/pages.yml`, `mutation.yml` and `mutation-pr.yml`. This is not a full docs inventory.

## Governing rules that apply to every later phase

- Under the owner's automatic-through-Phase-10 authorization, a phase advances when the preceding phase's written exit criteria are verified and recorded. Routine phase advancement needs no new approval. This does not waive the written checks or separate approvals for corrections, production changes, limits, test removal, final certification or requirement/security-scope changes.
- Finding status (5.1) and property certification status (5.2) are separate fields. Evidence gaps are tracked apart from both.
- No Proven claim comes from "no counterexample found" without an added argument for the complete domain and an independently justified oracle.
- Concurrent preparation is allowed; it does not close a phase or authorize implementation. Shared governing records, approved model-input packs and overlapping source files have one writer at a time.

## Current position that these phases wait on

| Item | Current record |
|---|---|
| Phase 4 | Closed (D66, D71). The domain work ledger lists eight work families (state-space attacks, every writer, every route, outer layers, protection attacks, independent expectations, original candidate sequence, cache and platform), closed from existing records. |
| Phase 3 | DECISIONS.md "Later formal Phase 3 gate" records the completed D50 publication gate. The dated followthrough receipt page is deleted and its receipt is accepted as lost. The scoped appropriate mapping and advancement record is operative with its stated limitations. Four approved phone relations (both quick taps reaching the game, double-tap recovery, zoomed-reload recovery, exact cached phone-file identity) remain Not Established. Publication does not make any property Proven. The earlier limited-advancement decision remains as history. |
| Finding states | The finding states in the blueprint's carried record (F18 Rejected, F19 Fixed historically, F20 to F24, Q1 to Q3, L1, N1, P7, S5 Candidate) are historical, not the current backlog. Later scoped dispositions in DECISIONS.md govern. Of the six reviewed Confirmed Defect rows, five (paused held soft-drop callback checkpoint, New Game withdrawal before a later factory fault, input disconnect cancellation refusal, failed-download deletion of a foreign cache binding, retained lock callback after registration throw) were recorded only in the deleted status page and are accepted as lost; the sixth (Continue eligibility-read failure causing withdrawal) is now recorded in DECISIONS.md. Examples read: the injected zero-cell piece and controller A selected-Cancel dispositions, and scoped records on F23 serializer failure, F24 eligibility read, new-save reset count, paused count15 Resume, stored high-score read, failed-withdrawal Continue availability and lowest-row history. F21 is a Confirmed Defect at injected scope (D74, Phase 5 records section 3B); Q2 has a source-argument disposition at the injected boundary only. Each is scoped, none implies broad parent closure, and every original parent finding still needs its own reconciliation. |

| Correction work | Current narrow correction status lives in [AUDIT F25](../../DECISIONS.md). PR171 and PR172 do not close SAF-3, SAF-4 or Phase 4. Other correction families retain their own gates. |

## Phase 5: classification and certification

Exit (blueprint): every finding has one finding status, every property has one certification status, no finding remains Candidate (D78 lets item 26 stay Candidate under its approved limit), no in-scope property remains Not Assessed.

| Exit field | Needed input | Waits on |
|---|---|---|
| One finding status per finding | A reconciliation of every original parent (F18 to F24, Q1 to Q3, L1, N1, P7, S5 and the other blueprint records) with every later scoped disposition, using only the 5.1 states (Candidate, Reproduced, Not Reproduced, Rejected, Requirement Clarification, Confirmed Defect, Fixed, Reverified, Folded into F20, Closed (historical note)). A scoped result is not applied to the whole parent | Remaining Phase 4 results: [D53](../../DECISIONS.md) records last-good identity, not complete preservation; [F29](../../DECISIONS.md) and [F20/S6](../../DECISIONS.md) retain independent prior-good saved-content evidence; [F21/Q1/Q2](../../DECISIONS.md) retain malformed-state partitions and admission; [F23](../../DECISIONS.md) retains ordinary/native causes and wider compositions, separate from its recorded injected-domain disposition; L1 still needs its exact trace. R1-R5 decisions are recorded. |
| One certification status per property | A 5.2 status for each of the 55 in-scope requirements and each adopted property O1 to O8 | Phase 3 mapping records and the four Not Established relations; Phase 4 domain results |
| No Candidate left | Any applicable non-Candidate 5.1 state for every parent finding and each later scoped disposition, including Reproduced, Not Reproduced, Rejected, Requirement Clarification, Confirmed Defect, Fixed, Reverified, Folded into F20 or Closed (historical note) | An owner-approved limitation is not a 5.1 state and does not waive the no-Candidate exit unless an approved exit-rule amendment is recorded; D78 is that amendment, for item 26 only |
| Proven claims | Named argument or full finite domain, assumptions, independently justified oracle | O8 model independence and correspondence record |
| 5.3 evidence record per final claim | Requirement or property, claim, method, assumptions, covered production code, covered model code if applicable, evidence, limitations, status, approver | Exact file and commit bindings, which change if source changes |

Preparation that can run now: a blank claim-status worksheet keyed by requirement ID and finding ID; a list of Candidates whose scope depends on an unrecorded decision. It must not pre-fill statuses.

## Phase 6: correction

Exit: every confirmed defect has an owner-approved minimal correction and a defined regression test.

| Exit field | Needed input |
|---|---|
| Defect classified | A Confirmed Defect status from Phase 5 |
| Violated requirement or property named | Requirement ID and the R-decision that governs it |
| Smallest correction | A conceptual change, not an architecture rewrite; construction hypotheses in 6.1 are hypotheses only |
| Regression test defined | An expected result with independent justification, not copied from the implementation |
| Collateral behavior | The protections plausibly affected, bounded to the corrected property |
| REQUIREMENTS.md change class | Refactor, Bug Fix, Intentional Change or Clarification, with that class's evidence |
| Owner approval | Per correction; the existing review of timer, Resume and notice text candidates is not approval |

One conceptual defect per PR. Per-defect implementation before the applicable phase gates needs a separate explicit amendment. Dependencies across corrections that the blueprint names: fault cleanup, reporting, persistence ordering, timer and input lifecycle. The timer candidates already note that existing mocks need approved interface updates and that coverage and mutation gates cannot be weakened to make a proposal pass.

## Phase 7: implementation

Exit: each approved change is made and its verification is recorded.

Per change, the blueprint lists nine steps. Repository scripts that map to them, as read from `package.json` and `stryker.config.json`:

| Blueprint step | Repository command or setting | Note |
|---|---|---|
| Focused tests, relevant complete suite | `npm test` (node test runner, coverage on `public/game/**`) | Coverage flags require 100 for lines, branches and functions |
| Coverage | same command | Threshold enforced by the flags |
| Mutation analysis | `npm run test:mutation` (Stryker) | Thresholds high 100, low 95, break 100; the command runner lists eight unit test files |
| Browser tests | `npm run test:e2e` (Playwright, then `scripts/browser-coverage.js`) | Three configured projects: simulated phone-sized WebKit, simulated phone-sized Chromium, and desktop Chromium; no physical device |
| Type checks | `npm run typecheck` | Two tsconfig projects |
| Whole check | `npm run test:all` | Typecheck, unit tests, e2e; does not include mutation |
| CI workflows read | `pages.yml`: on pull requests and main, a `test` job runs typecheck, `npm test`, Playwright browser install and `test:e2e`; a `deploy` job needs `test` and is skipped on pull requests. `mutation.yml`: weekly and on demand, runs `test:mutation`. `mutation-pr.yml`: runs on pull requests that touch `public/game/**`, `test/**` or `mutation-pr.yml`; changes under `test/` or to `mutation-pr.yml` itself run the full mutation set, while game-logic-only changes mutate just the changed `public/game/*.js` files | Enforced repository settings are not covered here |
| Diff inspection | Manual | Unrelated cleanup is not allowed in a correctness fix |

For PR171 and PR172 (status in [AUDIT F25](../../DECISIONS.md)), reconcile preserved exact-source before/after, browser, mutation, collateral and publication evidence against the applicable gates. PR171 and PR172 are implemented. Their verification evidence is not yet reconciled, and PR summaries and regression declarations are not full certification.

Each PR also states its change class and records in DECISIONS.md any finding it confirms, fixes or rejects. Runs happen only after owner approval of the specific production change. Nothing was run for this register.

## Phase 8: re-prove and re-falsify

Exit: original counterexamples re-falsified, evidence for the corrected property repeated, and any protection the correction could affect repeated.

| Correction touches | Repeat |
|---|---|
| Authoritative transition boundary | Boundary-bypass analysis |
| Persistence | O4 ordering tests |
| Invariants | Malformed-state attacks |
| Timers | Timer-state and timing evidence |
| Model | O8 independence and correspondence |
| Unrelated area | Nothing extra |

Dependencies: the original reproduction record for each defect (exact harness, seed, bound and raw log where used). L1's exact trace is unrecoverable and was replaced by the D69 runs (Phase 5 records section 4). DECISIONS.md also notes that earlier raw archives are not recreated by migration, so any counterexample that cannot be replayed needs a recorded replacement reproduction before it can be called re-falsified. The pre-fix failing and post-fix passing regression result must both exist.

## Phase 9: final certification

Exit: every claim names method, assumptions, covered code or model, evidence and limitations, with owner approval.

Per requirement the blueprint asks for eight items: claim, establishing production code, evidence, assumptions, limitations, status, remaining evidence gaps, approving decision. The completion standard has fifteen conditions. Open dependencies visible now:

- Condition 5 to 8 (corrections, pre-fix regressions, reverification, re-falsification) need Phases 6 to 8.
- Condition 9 (declared domains exhausted, proven, or limited with approval) needs Phase 4 and any approved limits; the four approved phone limits cover only both quick taps reaching the game, double-tap recovery, zoomed-reload recovery and exact cached phone-file identity.
- Condition 10 (every limitation recorded) needs a limitation list drawn from Phase 3 and 4 records.
- Condition 12 uses [QA-1 through QA-6](../../REQUIREMENTS.md) at their existing scopes. It needs source-bound evidence of satisfaction and enforcement, not a new scope or weaker gate.
- Condition 14 forbids unsupported formal-verification claims; no Formally Verified status is available without a machine-checked proof.
- Condition 15 is owner approval of the final certification and resulting repository changes.

A green suite and a mutation score are evidence at their tested scope only.

## Phase 10: minimization

Exit: each removal states its replacement protection and the owner has approved it.

| Removal field (10.2) | Source of the answer |
|---|---|
| Protection the old test provided | Requirement tags are navigation only. Name the actual assertions, the independent expected-value relation, the protected boundary and input, and the mutation and regression evidence |
| Replacement protection | Another permanent test with same outcome, same property, same input or state, same authoritative boundary |
| Why sufficient | Coverage, mutation effectiveness, regression value, independent-oracle value and the specific safety property all preserved |
| Authorizing requirement | A requirement change under REQUIREMENTS.md rule 2, or unchanged requirements under the same-outcome rule |
| Coverage and mutation gates | 100 percent coverage flags and mutation break threshold 100 stay satisfied |
| Owner approval | Required per removal |

10.1 trusted-core minimization needs, per trusted component: responsibility, assumptions, evidence, authority to mutate authoritative state, ability to bypass the boundary. Appendix E lists trust-ledger candidates as of an earlier point; its completeness is a Phase 1 and Phase 9 condition. CI speed work is deferred until after Phase 10 (D12), measured against the Phase 0 baseline.

## Cross-phase dependency order

1. Phase 4 domain families and candidate reproduction (closed).
2. Phase 5 statuses, after Phase 4 results and any approved limits.
3. Phase 6 corrections, one per confirmed defect, each with owner approval.
4. Phase 7 implementation, only for approved changes.
5. Phase 8 re-proof, per correction scope.
6. Phase 9 certification, after 5 to 8.
7. Phase 10 minimization, after 9.

Each arrow is an exit-check gate, not a new owner approval request for routine phase advancement. Phases 5 to 10 can have unrelated preparation proceed in parallel, but a blocked item does not block unrelated authorized preparation and does not authorize its own successor.

## Owner approvals still required

Each limitation not covered by proof; each correction and its regression test; each production change; any permanent test removal; final certification; any requirement or security-scope change. None is assumed here.

## What remains

This register does not decide any finding status, count requirements per status, or schedule work, and it gives no finish estimate. Claim-status counts and the completeness of the Appendix E trust ledger are unreviewed. Phase 4 is closed (D66, D71); no property newly certified.

## Phase advancement authorization

This corrects the earlier claim that every phase exit needs a new owner approval. Automatic progression through Phase 10 was authorized separately and remains conditional on verified, recorded written exit checks. It is not approval to skip a phase, certify an unproved claim or perform a reserved action. This wording change does not edit the blueprint, requirements, code, tests, models, CI or settings.
