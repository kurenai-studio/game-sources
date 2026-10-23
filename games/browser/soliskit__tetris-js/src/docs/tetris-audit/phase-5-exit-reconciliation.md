# Phase 5 exit reconciliation

Read-only record. No code, test, requirement or CI change. Prepared by the auditor; enters the repository through the usual docs review gates.

## 1. Original findings matched to the decisions that narrowed them

The Phase 5 exit list (section 6) names F18 to F24, Q1, Q2, N1 and P7. Each is matched here against the later decisions and records that narrowed it.

| Finding | Word | Match |
| --- | --- | --- |
| F18 | Rejected | Repeating the same fault after a safe stop is harmless: the record is bounded and New Game or Continue replaces the broken state (PR #40). No later narrowing. |
| F19 | Settled (fixed historically) | DECISIONS records the row Settled; fixed in PR #42. Reverification under this audit is pending; no current verification is claimed. |
| F20 | Confirmed Defect (source argument) | Both halves recorded: the reset-count loss and the lowest-row loss ("New-save reset-count preservation disposition" and "Lowest-row history: ordinary rotation information loss" in DECISIONS.md). F29 is Folded into F20 (D77). The defect stands; no fix is approved. |
| F21 | Confirmed Defect (injected scope) | Set from a run (D74). The migrated d74-f21-f22-p7 test watches it as a todo test. |
| F22 | Not Reproduced | Set from a run (D74, D75). The audit's setting S10 is kept. |
| F23 | Confirmed Defect | Recorded by the owner (D73) at the scope of its existing record. |
| F24 | Confirmed Defect (source argument plus qualified historical reproduction) | "Eligibility-read failure: Continue withdrawal disposition" in DECISIONS.md. The constraints a later minimal fix must keep are recorded there. The defect stands; no fix is approved. |
| Q1 | Reverified (injected scope) | The two admitted malformed queues (dense null entries; a sparse length-3 list) are rejected by the current queue-element check. Evidence in section 2. |
| Q2 | Reverified (injected scope) | The admitted zero-cell falling piece is rejected by the current falling-piece check. Evidence in section 2. |
| N1 | Rejected | Set from a run (D74, D75). The audit's setting S2 is kept. The migrated d74-N1 test runs as an ordinary must-pass test. |
| P7 | Rejected | Set from a run (D74, D75). The audit's setting S11 is kept. |

## 2. Q1 and Q2 re-verification evidence

Both findings predate the current piece checks. The Q2 paper notes that the piece-checker change (PR 171) was not rerun or verified against it; the Q1 criteria note (queue-piece-check-decision.md) states the later PR 171 implementation is separate from its historical count-only comparison, without a rerun statement. This record closes that gap at the findings' stated injected scopes.

Evidence, all on the audited head (aea3589):

- The repository's own safety suite covers the findings' admitted inputs through guarded operations: the malformed-upcoming table (23 cases, including a null piece, holes and a zero-block piece) and the malformed-current table (the same 20 cases in each of the falling and paused states - 40 runs - including a piece with no blocks). Each case asserts the full safe stop: game over, every timer stopped, the fault reported with the exact reason. This suite runs in CI and was green on the audited head (the test job of the October 22 migration run).
- The auditor also spot-ran the findings' exact admitted inputs against the current predicates: the dense-null queue and the sparse length-3 queue are rejected by isValidPieceList, and the zero-cell yellow piece is rejected by isValidFallingPiece.

Limits: the evidence is at Node predicate and suite level, not a real browser. The papers' other partitions stay outside: other malformed shapes beyond the admitted ones, ordinary-writer creation of malformed state, native behavior, and full Q1, Q2 and R1 property coverage. The Reverified word covers only the injected scope each finding stated.

## 3. Requirement Clarifications

This reconciliation produces none. Every ambiguity it touched was already settled by the owner's detector-extent decisions; Q1 and Q2 needed status words, not clarifications.

## 4. Remaining exit state

- This record is the finding match the exit list asks for.
- The 55 in-scope requirements and O1 to O8 keep the certification statuses their cleared batches recorded; no final certification is claimed.
- Item 26 stays Candidate under its approved exception (D78).
- Phase 5 closure is not claimed here; the phase closes under the Audit Advancement Gate once its numbered exit checks are recorded as passed, with owner approval only where a check includes it (a Requirement Clarification, or an approved Not Established or Out of Scope disposition).
