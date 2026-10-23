# Phase 5 certification record

Read-only record. No code, test, requirement or CI change. Prepared by the auditor; enters the repository through the usual docs review gates.

This record collects the certification status for each of the 55 in-scope requirements and for the properties O1 to O8 (adopted in Phase 1, recorded in D25), from the audit's nine evidence batches.

Sources and provenance: evidence batch 1 (PCE), batch 2 (PLY, SCO), batch 3 (STA), batch 4 (SAF), batch 5 (INP), batch 6 (APP), batch 7 (DSP), batch 8 (QA), batch 9 (O1 to O8). Batches 1 to 5 and 9 passed independent review on their original final texts. The original evidence copies for batches 6, 7 and 8 are unavailable; their content was reconstructed, independent review passed the reconstructed content, and the original identity of those copies is unconfirmed, so the review of those three batches covers the reconstruction, not the originals. One table cell in batch 7 (DSP-2's status word) was edited after that batch's review round to align its wording with the other device rows; this record's review covers that edit.

Reading notes: words in quotes are the batches' own words. The batches use the shorthand "Partially" for the blueprint word "Partially Established". "(Inf)" marks auditor inference; "(Obs)" marks observation. Split words mean the requirement has two parts with different statuses; the split is the batch's own finding. Square brackets inside a quoted entry are this record's note, not batch text. The owner approvals named below are dated October 22, 2026 and are recorded in DECISIONS.md.

## Certification status of the 55 requirements

*For the 20 rows in decision sets A and B below, the owner approved these words on October 22, 2026. The remaining words are the audit's evidence-backed statuses from its evidence batches, recorded under the approved audit scope. The evidence, methods and limits for every row stay in the batch documents named in the sources note.*

| Requirement | Certification status | Evidence batch |
| --- | --- | --- |
| PCE-1 | Tested Within Stated Bounds | 1 |
| PCE-2 | Partially Established | 1 |
| PCE-3 | Partially Established | 1 |
| PCE-4 | Not Established | 1 |
| PCE-5 | Partially Established | 1 |
| PCE-6 | Tested Within Stated Bounds | 1 |
| PLY-1 | Partially Established (Inf) | 2 |
| PLY-2 | Tested Within Stated Bounds (Inf) | 2 |
| PLY-3 | Partially Established (Inf) | 2 |
| PLY-4 | Partially Established (Inf) | 2 |
| PLY-5 | Engine half Partially Established, display half Not Established (Inf) | 2 |
| PLY-6 | Not Established (Inf) | 2 |
| PLY-7 | Partially Established (Inf) | 2 |
| PLY-8 | Engine half Partially Established, display half Not Established (Inf) | 2 |
| SCO-1 | Partially Established (Inf) | 2 |
| SCO-2 | Proven by Reviewed Argument within the safe-integer range (Inf: argument and assumptions stated in the P3-C record, as blueprint 5.2 requires) | 2 |
| SCO-3 | Partially Established (Inf) | 2 |
| STA-1 | Partially (Inf) | 3 |
| STA-2 | Not Established for the resume-at-count-15 half (a confirmed defect, F34); Partially for the rest (Inf) | 3 |
| STA-3 | Partially (Inf) | 3 |
| STA-4 | Not Established for the "exactly" claim (confirmed defect F20); Partially for pause and clear saving (Inf) | 3 |
| STA-5 | Partially (Inf) | 3 |
| STA-6 | Partially (Inf) | 3 |
| SAF-1 | Partially (Inf) | 4 |
| SAF-2 | Partially (Inf) | 4 |
| SAF-3 | Not Established for "anything throws" (F23 confirmed defect and O-9); Partially for guarded entries (Inf) | 4 |
| SAF-4 | Not Established for the lock-delay and gravity timer detection under undefined handles (Q3); Partially for the rest (Inf) | 4 |
| SAF-5 | Not Established for the report half (no notice found, D68 defects open); Partially for loop continuation (Inf) | 4 |
| SAF-6 | Partially (Inf) | 4 |
| INP-1 | Partially (Inf) | 5 |
| INP-2 | Not Established for "repeating stops when the game stops playing" across pause (F33, F35); Partially for the rest (Inf) | 5 |
| INP-3 | Partially (Inf) | 5 |
| INP-4 | Partially (Inf) | 5 |
| INP-5 | Not Established for the tap-wobble half where F28b applies; Partially for the rest, including controls-only-its-piece (D70 stays with INP-7) (Inf) | 5 |
| INP-6 | Partially (Inf) | 5 |
| APP-1 | Partially for the repository-checkable half; device half Not Established | 6 |
| APP-2 | Not Established for the cleanup and version-consistency halves where F26 and F36 apply; Partially for the rest (Inf) | 6 |
| APP-3 | Partially (Inf) | 6 |
| APP-4 | Partially for the repository-checkable half; device half Not Established | 6 |
| APP-5 | Partially (Inf) | 6 |
| APP-6 | Partially (Inf) | 6 |
| DSP-1 | Partially for the repository-checkable half; device half Not Established | 7 |
| DSP-2 | Partially for the repository-checkable half; device half Not Established | 7 |
| DSP-3 | Partially (Inf) | 7 |
| DSP-4 | Partially for the repository-checkable half; Safari half Not Established | 7 |
| DSP-5 | Partially (Inf) | 7 |
| DSP-6 | Partially for the repository-checkable half; display half Not Established | 7 |
| DSP-7 | Partially for the repository-checkable half; device half Not Established | 7 |
| DSP-8 | Partially (Inf) | 7 |
| QA-1 | Partially (Inf) | 8 |
| QA-2 | Partially (Inf) | 8 |
| QA-3 | Partially (Inf) | 8 |
| QA-4 | Partially for the repository-checkable half; device half Not Established | 8 |
| QA-5 | Partially (Inf) | 8 |
| QA-6 | Partially (Inf) | 8 |

## Certification status of properties O1 to O8

Each adopted property records Partially Established, from the properties evidence batch (batch 9), with that batch's stated limits. No property is Not Assessed.

| Property | Certification status |
| --- | --- |
| O1 | Partially Established |
| O2 | Partially Established |
| O3 | Partially Established |
| O4 | Partially Established |
| O5 | Partially Established |
| O6 | Partially Established |
| O7 | Partially Established |
| O8 | Partially Established |

## Owner decision set A: rows or halves proposed as Not Established

The blueprint's Audit Advancement Gate has two rules that govern these proposals. Its completion rule: a phase is complete only when its declared evidence and exit criteria are satisfied, or an explicit Not Established or Out of Scope disposition has been approved. Its neighbor rule: a requirement or security-scope decision may be proposed during its phase but may not be implemented without explicit owner approval. The owner approved the twelve dispositions below on October 22, 2026: each row records as proposed, with its gap and register entries named, and fixes stay under separate approval. Each entry quotes the batch's word, adopted unchanged, and its stated limit. Split words stand exactly as proposed: halves with partial evidence keep Partially; only the named halves carry Not Established.

- **PCE-4** (batch 1). Approved word: "Not Established". Limit: The ordinal visitor method used a stand-in for fit, not real-board collisions; counterclockwise fallback tests are selected cases, not exhaustive
- **PLY-5** (batch 2). Approved word: "Engine half Partially Established, display half Not Established (Inf)". Limit: Display half has no browser evidence; ghost also shows while paused (requirement silent) (Obs)
- **PLY-6** (batch 2). Approved word: "Not Established (Inf)". Limit: B9.2 is the lock-delay rule in phase-1-r1-decision.md line 35; the public traces are in phase-3-differential-evidence.md sections 2 and 3. Register: F34 (resume at count 15 locks at once, requirement says only 16 does; reproduced on main with the count set directly, register state Pending work) and F20 (the save keeps neither the reset count nor the lowest row; Pending work). Also recorded in P3-C, not traced to a register row: off-ledge move adds 1 and can reach 16 while playing; lowest-row reference uses the piece's box row; new lowest row ends at count 1 not 0. Rotations, real delay and real timers unassessed (Obs). The blueprint has no word for a row with a confirmed defect, so Not Established here is an audit proposal (Inf)
- **PLY-8** (batch 2). Approved word: "Engine half Partially Established, display half Not Established (Inf)". Limit: Display half has one e2e test and no visual verification; post-queue semantics and pixels not compared (Obs)
- **STA-2** (batch 3). Approved word: "Not Established for the resume-at-count-15 half (a confirmed defect, F34); Partially for the rest (Inf)". Limit: Held controls across pause (F33, F35, both Pending work) belong to INP rows (Obs)
- **STA-4** (batch 3). Approved word, verbatim: Not Established for the "exactly" claim (confirmed defect F20); Partially for pause and clear saving (Inf). Limit: "Exactly what was saved" has no route for the reset count or lowest row (P3-D G-4). Real storage failure and other tabs beyond :394 are not shown. Test :873 shows Continue starts a fresh delay, so the count is not restored. P3-D O-3 says B16 and D32 call for exact restore; I did not open those texts here (Obs; Inf for the tension)
- **SAF-3** (batch 4). Approved word, verbatim: Not Established for "anything throws" (F23 confirmed defect and O-9); Partially for guarded entries (Inf). Limit: The P3-D limit that no player message exists is out of date, since F25 was fixed (Obs). Held-control, dialog and drag state are not reset by the stop; input timers stop only when they fire (P3-D). F23 is outside the guarded entries (Inf)
- **SAF-4** (batch 4). Approved word: "Not Established for the lock-delay and gravity timer detection under undefined handles (Q3); Partially for the rest (Inf)". Limit: Not checked by the monitor: queue element validity, hold state, bag, reset count range, lowest row, repeat timers, touch state (P3-D). The score check enforces multiples of 100 where B11 says none (O-7). The undefined-handle case is not among the ten injected breaks (Obs)
- **SAF-5** (batch 4). Approved word: "Not Established for the report half (no notice found, D68 defects open); Partially for loop continuation (Inf)". [Record note: "reported" in this row uses the batch's P3-D definition, a small player notice plus a separate test signal; the console error report exists and D68 records it with its defects open, so "no notice found" means no player-visible notice, not no report at all.] Limit: A gamepad error logs on every frame. Errors outside the guarded drawing function (observers, first draw, module setup) are not covered (P3-D). Real drawing failures and real gamepads not run (Obs)
- **INP-2** (batch 5). Approved word, verbatim: Not Established for "repeating stops when the game stops playing" across pause (F33, F35); Partially for the rest (Inf). Limit: Pad soft drop has no immediate first row (P3-D O-13). Pause and resume faster than a tick keeps timers alive (P3-D O-2, the pause-and-resume timer item; the STA batch cited a different P3-D O-2, the hidden-or-blurred held input item). Real timing, real gamepads, other controls not shown (Obs)
- **INP-5** (batch 5). Approved word: "Not Established for the tap-wobble half where F28b applies; Partially for the rest, including controls-only-its-piece (D70 stays with INP-7) (Inf)". Limit: Real phone sequences, Safari and the with-move far-lift case are not shown (D72e). Item 14 gesture state sits outside the engine commit point (P3-D). Touch begun while paused creates a drag piece (P3-D) (Obs)
- **APP-2** (batch 6). Approved word: "Not Established for the cleanup and version-consistency halves where F26 and F36 apply; Partially for the rest (Inf)". Limit: F26 and F36 are confirmed against the cleanup and version halves and no test covers their schedules. Clock jumps, malformed pins and foreign partial caches are named gaps (P3-E). Simulated browsers, not a phone (Obs)

## Owner decision set B: the eight device-half rows

Eight rows have a half that repository evidence alone cannot test, because the half needs a real device (real Safari, a real iPhone install). For these rows the audit's working certification checklist marks the tested word as unreachable from the repository alone. The owner chose Not Established for all eight named device, display and Safari halves on October 22, 2026, keeping the rows in scope and leaving the path open for later device evidence. Each row's repository-checkable half keeps Partially, and new device evidence can support a reviewed upgrade of a device half with the owner's OK. The approved disposition stated here is the current word for each row's device, display or Safari half as the row names it, including DSP-4's Safari half and DSP-6's display half; DSP-4's proposal had named row 26's limit as one path. The batch wordings quoted below are the pre-decision wordings, kept as the evidence record. The gate's completion rule (set A) allows an approved disposition; an approved per-row limit remains a separate path, and row 26's approved limit under D78 (DECISIONS.md; phase-5-records.md, section 6) is the existing example of that path. The eight rows:

- **APP-1** (batch 6). Batch wording: "Partially for the repository-checkable half; the device half needs device evidence or an approved limit (Inf)". Limit: The e2e check skips WebKit ("Safari has no install check to query", app.spec.js:104), so Safari never runs it. Icon pixels not visually inspected, headers only. No real device install or launch (D15 gap, P3-E) (Obs)
- **APP-4** (batch 6). Batch wording: "Partially for the repository-checkable half; the device half needs device evidence or an approved limit (Inf)". Limit: No real iOS 27 or Safari 27 device evidence exists (D15 gap, P3-E); configured WebKit at iPhone size is not an iPhone. [Set-membership sentence elided; the set intro states it for all eight rows.]
- **DSP-1** (batch 7). Batch wording: "Partially for the repository-checkable half; the device half needs device evidence or an approved limit (Inf)". Limit: "On a phone" is configured emulation, not a device (D15 gap); real Safari toolbars and safe areas are not shown (P3-E). [Set-membership sentence elided; the set intro states it for all eight rows.]
- **DSP-2** (batch 7). Batch wording: "Partially for the repository-checkable half; the device half needs device evidence or an approved limit (Inf)". Limit: The density change is stood in: Chromium 153 stopped firing the media-query change under emulation, so the test dispatches the event itself with the ratio set to 2 (test comment). Not a real move between screens, and mostly the board canvas is checked, not all 5 (P3-E). Device gap (Obs)
- **DSP-4** (batch 7). Batch wording: "Partially for the repository-checkable half; the Safari half sits under row 26's approved limit or needs device evidence (Inf)". Limit: No real Safari behavior is shown (D15 gap); the two touch tests are Chromium-only, and I found no test for the zoomed-reload recovery gestures in the lines read (Inf; title grep). Row 26's limit covers exactly this unknown (Obs) [accuracy note: the "two touch tests" are the two DSP-4-tagged quick-tap tests; a third Chromium-only touch test, the hold-box tap, skips non-Chromium at e2e/touch.spec.js line 218]
- **DSP-6** (batch 7). Batch wording: "Partially for the repository-checkable half; the display half needs device evidence or an approved limit (Inf)". Limit: No real Display P3 screen observed (D15 gap). The contender test covers DOMContentLoaded, not any earlier acquisition (P3-E). I found no test for the saved-games-keep-colors clause in the tagged tests (Inf; title grep) (Obs)
- **DSP-7** (batch 7). Batch wording: "Partially for the repository-checkable half; the device half needs device evidence or an approved limit (Inf)". Limit: The wake lock is a stand-in; no real screen sleep or system revocation (D15 gap). P3-E also names a synchronous request throw, release rejection and listener-failure cases as open (Obs)
- **QA-4** (batch 8). Batch wording: "Partially for the repository-checkable half; the device half needs device evidence or an approved limit (Inf)". Limit: WebKit at iPhone size is not Safari 27 on an iOS 27 device (D15 gap, P3-E); some tests skip WebKit by design (install check, two touch tests, named in batches 6 and 7), so "pass" there includes skips. Per-project logs not read. [Set-membership sentence elided; the set intro states it for all eight rows.] [accuracy note: three touch tests skip non-Chromium on main, e2e/touch.spec.js skip lines 188, 204 and 218; the batches named the two quick-tap tests]

## Note on rows with a confirmed defect

Several set-A rows are Not Established because of a confirmed defect (the batches name F20, F23, F26, F28b, F33, F34, F35, F36, Q3 and D68 across those rows). Batch 2 states the blueprint has no status word for a row with a confirmed defect, so the Not Established word there was an audit proposal marked (Inf), not a blueprint rule. The owner's set-A decision (approved October 22, 2026) settles this convention: defect-bearing rows carry Not Established on the affected halves, as recorded above.

## Note on INP-7

INP-7 (first-finger choice) is not yet a requirement row in REQUIREMENTS.md; D70 records the choice and the traceability check fails until the row is added. Adding it is a requirement change outside this record. This record covers the 55 rows that exist today.

## What this record does and does not do

- It adopts sets A and B only, as recorded above, under the owner approvals of October 22, 2026. Any further status change (an upgrade from new evidence, an Out of Scope choice, any fix) needs its own approval.
- It is not the Phase 9 final certification gate; it is the Phase 5 per-row status collection that gate will build on.
- It does not close Phase 5; closure waits for the remaining exit checks. SCO-2's word stays an auditor-inference word: blueprint 5.2 expressly requires that a Proven by Reviewed Argument claim state its argument and assumptions, and the P3-C record states them; the blueprint names no separate Phase 5 acceptance step for this word. The word's limit is the stated assumption range: scores above MAX_SAFE_INTEGER are rejected (GM:418, SS:160), the page does not show the level, and the level reaches the player only through gravity speed (PLY-2).
- It does not decide INP-7, any fix, any limit approval, or any device-evidence plan; it only lists where each is needed.
