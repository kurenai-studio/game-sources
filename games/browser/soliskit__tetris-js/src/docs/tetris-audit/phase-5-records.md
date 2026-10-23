# Phase 5 records

The evidence behind decisions D66 to D75.

Nothing here changes code, tests, requirements, CI (the automated checks that run on each change), or the public site. Source: the audited Tetris code at commit `06a43a9`. "The auditor" performed the checks, by run or by code reading.

Terms:

- Node runs JavaScript outside a browser. Chromium is the open browser engine behind Chrome; a Chromium-only run is not a Safari or iPhone run.
- Outside audits are reviews of the game run by people or tools outside this project.
- SAF-n, INP-n, and QA-n are entries in `REQUIREMENTS.md` (safety, input, and quality gates). R1 and B13 are the audit's valid-state decision and its runtime-resource rule. TE1 and TE2 are the two parts of finding F28.
- A plain number (row 7, row 26) is an item's position in the audit's findings list. A letter plus a number (F26, Q3, S5, P7, L1, N1) is a finding's name from the earlier audit records, so some findings have both.
- O1 to O8 are the eight properties the owner adopted for the whole game, such as valid transitions and validated saved state (blueprint section 5.2 lists the status words each one can get).
- Source argument: a conclusion from reading the code, not from running it.
- Candidate is a finding with no final status yet. Confirmed Defect means found and scoped, with no fix approved. The audit blueprint (the audit's governing plan) also allows Reproduced, Not Reproduced, Rejected, Requirement Clarification, Fixed, Reverified, Folded into F20, and Closed (historical note) (status words, blueprint section 5.1).

- Tested Within Stated Bounds: the claim, as the row bounds it, is fully covered by a test or run over a finite set of cases the row names, and nothing outside that set is claimed. Partially Established: the requirement itself is only partly shown, and the row names the part it does not show.

- Closed (historical note) (F32e) and Folded into F20 (F29) are the finding states added in D77. The assistant wrote both names from the owner's D72 decisions.

## 1. Decision-log rows

Decisions D66 to D75 are recorded in [DECISIONS.md](../../DECISIONS.md). The sections below hold the evidence they cite.

## 2. Status table for the October 17 items (labels from blueprint section 5.1)

Row 7 is Not Reproduced: no attempt showed the problem, which does not mean the code is right. Row 26 is a Candidate until the owner decides a final status. For row 26 the one real-iPhone attempt cannot show the taps were fast enough, so no word is proposed. The owner approved each limit on October 17; section 3 records them in this wording.

| Item | Status | Basis | Limit |
| --- | --- | --- | --- |
| Q3 | Confirmed Defect (injected case) | Source argument against B13; D67 | Not run; a real browser timer returning undefined not shown |
| S5 | Reproduced (rows 5, 10, 61) | Run October 16, Chrome 154 (as the outside audit reported), injected state; D68 | Cache clearing not shown |
| L1 | Not Reproduced | Traces in section 4; D69 | See D69 |
| Row 4 | Confirmed Defect | Run; D70 | Chromium, simulated touch, not a phone |
| Row 7 | Not Reproduced (limit approved) | Emulated changes fired no event; the handler works when given one directly | Section 3, limit 1 |
| Row 26 | Candidate, under its approved limit (D78) | One real-iPhone attempt, inconclusive (taps not visible); the auditor checked the viewport, touch-action, and zoom-gesture rules in the source | Section 3, limit 2 |
| Row 68 | Reproduced (limit approved: device part untested) | Run October 16, Chrome 154 (as the outside audit reported), GPU crash | Section 3, limit 3 |

## 3. Limits

1. **Row 7.** Emulated pixel densities fired no event; with a test standing in for the event, the handler rebuilt the canvas each time. Outside audits disagree: one saw the canvas follow the change in Chromium 141, and one saw no canvas change in Chromium 144. Needs a real window moved between two displays of different density.
2. **Row 26.** Chromium cannot show this Safari behavior. Rules the auditor read in the source: `user-scalable=no`, `touch-action: none` on the board, zoom gestures blocked in `public/script.js`. A recording of the taps cannot show they came fast enough to count as the double tap that zooms. Needs a real-iPhone test where the taps are visible.
3. **Row 68.** A GPU crash (the browser's graphics process stopping) in Chrome 154 (as the outside audit reported) cleared all five canvases; after the game resumed, the board came back only in the top-left quarter and the previews stayed empty. Two real-iPhone screen locks, of 1 and 5 minutes, left the board and piece intact; they do not show a surface loss. Untested: iPhone surface loss and restore, an app switch, a long time in the background, a page dropped from memory. The row stays Reproduced for the desktop run; the device part is the limit.
4. **Offline install source.** Offline rows 8, 13, 19, 24, 70, 71, and 79 ran in Chromium on local servers. The auditor's installed-app test asks Chromium only whether the page qualifies as installable. It cannot show an installed icon, a fullscreen UI, or a physical installation (`docs/tetris-audit/phase-4-outer-browser-expectations.md` line 57). The auditor did not run a real install from the live host.
5. **Timing beyond level 1.** For row 76, the auditor calculated the drop speed at levels 2, 3, 8, 11, and 23 from the formula. The calculation says nothing about when the browser fired each timer. Real timing above level 1 needs long physical play.

## 3A. Phase 4 family results (all eight closed from existing records)

The auditor read the Phase 4 ledger and its supporting records at commit `06a43a9`; nothing was re-run.

| # | Family | What the records show | Open items carried as limits |
|---|---|---|---|
| 1 | State-space attacks | Current-piece and queue checkers; Q1 and Q2 source-argument dispositions (queue-checkpoint-detector-disposition.md, zero-cell-current-piece-detector-disposition.md) | The full valid and invalid partition was not reconciled; the PR #106 publication receipt is not independently reconciled (PR #171 is not a substitute) |
| 2 | Every writer | 35-row writer and route index (2-phase-4-writer-route-index.json); storage-write ledger (phase-4-persistence-effect-premises.md) | The index states not all writers and routes were reconciled; no independent known-good prior save (F29) |
| 3 | Every route | New Game failure and paused soft-drop records (preserved outcomes in phase-4-domain-work-ledger.md) | Per-route reconciliation was not done |
| 4 | Outer layers | phase-4-outer-browser-expectations.md; drawing console decision (drawing-console-report-policy.md); S5 Reproduced for rows 5, 10, and 61 (D68) | Native and physical-device gaps, except the five approved limits (D66) |
| 5 | Protection attacks | Result of the score-check variant test against a scratch copy (an altered copy used only for the test); the result is named in the Phase 4 ledger, and the archive file is not in the repository | How completely the mutation tests catch seeded faults (QA-6) was not assessed; the named result covers one historical variant |
| 6 | Independent expectations | phase-4-unit-expectations.md; phase-4-selected-independent-expectations.md; phase-4-selected-browser-expectations.md; 25-row geometry literal comparison | The complete selection of important tests, and the raw receipts, are missing |
| 7 | Original candidate sequence | Records for F20, F23, F24, F33 to F35, and F37; Q3, S5, and L1 with the status words the owner set on October 17 (D67 to D69) | The ledger has no disposition for F22, N1, and P7 (section 3B records them and F21); the 3,738-lock trace has no seed or raw log (replaced by the L1 runs, D69) |
| 8 | Cache and platform | Cache deletion and reopened identity record (preserved outcomes in phase-4-domain-work-ledger.md); offline rows run in Chromium | Native install and physical timing, except the five approved limits (D66) |

The Phase 5 exit rule needs its own decision for any open item that stays a limit (section 6). D78 makes that decision for item 26 only.

## 3B. Status words for the open and split findings

Recorded: the owner chose the status word (D72 to D75). Set from a source argument: the auditor reads the code at the finding's stated scope and reports one line per row (D72 rule). Set from a run: the word follows a read-only run, as D72 and D74 allow. Unchanged: the word was already final before this record. F32 is the confirmation-dialog focus item, split into parts a to e. F25 and F32 b are listed for completeness; their words did not change.

| Finding | Word | State | Scope and limit |
|---|---|---|---|
| F23 | Confirmed Defect | Recorded (D73) | Source argument, not run. Injected nonstorage serializer exception swallowed; Pause stays paused with no required SAF-3 stop or test signal. No ordinary or native cause claimed |
| F26 | Confirmed Defect | Recorded (D72) | Conditional source argument. A forward clock jump can lose the page's cached version. Not run; backward jumps and other loading schedules not covered |
| F27 | Confirmed Defect | Recorded (D72) | "If another project uses either name". Source argument; the other-owner condition is not checked |
| F36 | Confirmed Defect | Recorded (D72) | Conditional source argument with a long first download; native worker lifetime not measured |
| F29 | Folded into F20 | Recorded (D72) | No independent good save exists; carried as a limit |
| F30 | Rejected as a defect | Recorded (D72) | Test strength; limits carried to the certification table |
| F31 | Rejected as a defect | Recorded (D72) | Coverage; limits carried as the Phase 4 family limits (D71) |
| F28 TE2 | Confirmed Defect (synthetic event) | Set from a run | The D72 run, in Chromium with simulated touch: the code counts a lift 60 px from touch-down as a tap when no move event arrives in between; the tap rule allows only lifts within 10 px. The run covered only the no-move case; a lift far from where a move ended (the with-move case) was not run. The far lift was synthetic; a real phone sending it is not shown. Not run on WebKit (Safari's engine) |
| F32 a | Rejected | Set from a source argument | Source argument, with one earlier local Chrome run as context: clicking the dialog text moved focus, the game stayed paused, and the question stayed open. The finding's claim beyond that was not shown |
| F25 | Fixed | Unchanged | Fixed in commit `f186150` (player-message half); full SAF-3 and the test-signal half stay Not Established |
| F32 b | Confirmed Defect | Unchanged | Confirmed at its stated scope |
| F32 c | Confirmed Defect | Set from a source argument | Programmatic or direct events only; the native cut is open |
| F32 d | Rejected | Set from a source argument | A real click cannot reach Resume while the dialog is open; assistive events not covered |
| F32 e | Closed (historical note) | Set from a source argument | An old note about an unfinished check |
| F21 | Confirmed Defect (injected scope) | Set from a run (D74) | The safety check accepts a directly written board that is missing a row or cell; shown by a run in Node. Not shown reachable by ordinary play or by a save |
| F22 | Not Reproduced | Set from a run (D74, D75) | At levels 1 to 2,000 the measured gravity delay matched the requested delay within a billionth of a millisecond (0.000000001 ms), run in Node. S10, the audit's setting, is kept (D75) |
| N1 | Rejected | Set from a run (D74, D75) | A fault after a confirmed New Game keeps the old save withdrawn and the saved text as it was, run in Node. S2, the audit's setting, is kept (D75) |
| P7 | Rejected | Set from a run (D74, D75) | The game accepted a hand-edited save that granted one more hold than the rules allow, after loading and resuming, run in Node. S11, the audit's setting, is kept (D75) |

## 4. L1 evidence

- Replacement random trace: `l1-trace-harness.mjs`. Each run stops at 3,738 locks, the original trace's count. Seed 20261017: 281 games, 1 line clear, 0 rule violations, 0 monitor faults. Seed 2024: 283 games, 0 clears, 0 rule violations, 0 monitor faults. Node 22, simulated clock, up to 2,000 steps per game.
- Queue, bag and save restore after a clear: `l1-clear-after-harness.mjs`, 800 trials (seeds 1 to 200, clear sizes 1 to 4, a Hold first on even seeds), 0 failures. The harness injects the current piece as a vertical I into column 9.
- Repository test cases that remain the line-clear evidence: `test/gameManager.test.js` lines 281 to 288 (1 to 4 rows), 291 to 316 (rows above, split rows), 318 to 326 (one level boundary), 408 to 418 (save after a clear), 988 to 998 (a clear that ends the game); `test/safety.test.js` lines 189 to 202 (monitor silent through a full game cycle, including a clear).
- The random traces rarely clear a line (1 and 0 clears), so the clear evidence is the 800-trial run and the repository cases above. Not covered: pieces other than a vertical I, repeated clears, clears across more than one level boundary, a real browser, and real storage.
- These harnesses are not in the repository, so these runs cannot be replayed from it.

## 5. Requirement entry for the first-finger choice

The owner chose on October 14 that the first finger keeps control of the piece and the second finger does nothing to gameplay (D70), and on October 22 to add one clause to INP-7 that D70 does not state: a second finger also means the gesture no longer counts as a tap.

Proposed row for `REQUIREMENTS.md`, added in the same commit as the fix (rule 1 of its "Rules for changes"), not before:

| ID | Requirement |
| --- | --- |
| INP-7 | Touch, second finger: While one finger is dragging, a second finger touching the screen does not take over the drag; its movement and release do nothing to the game. A second finger also means the gesture no longer counts as a tap, so lifting the first finger does not rotate the piece. |

The traceability test fails the build when a requirement ID has no test. Until that row is added, D70 records the choice. Class when added: Intentional Change (a requirement that changes behavior the code has today; the code lets the second finger take over, row 4).

## 6. Before Phase 5 exits

- Match each original finding (F18 to F24, Q1, Q2, N1, P7) against the later decisions that narrowed it.
- Give each of the 55 in-scope requirements a certification status from the Phase 5 column of the scope table, and give O1 to O8 their statuses from blueprint section 5.2.
- Phase 5 cannot exit while any finding is Candidate (blueprint, exit criteria for Phases 2 to 10). The one exception is item 26 (row 26 in this file), which D78 lets stay Candidate under its approved limit; any other limit would need its own exit-rule amendment. Closed (historical note) and Folded into F20 are listed in blueprint section 5.1 (D77), so they are final states.
- Every Requirement Clarification found in that reconciliation needs the owner's yes.
