# Blueprint appendix coverage sweep for the Phase 5 finding records

Read-only grounding record. No code, test, requirement or CI change. Prepared by the auditor. This record adopts no status word, closes nothing, and adds no finding to the crosswalk's roster; it records one bounded sweep of the blueprint's per-finding appendix (the "Current audit finding record" section, carried forward from prior audit work) as grounding for the crosswalk's open finding-ID coverage question.

## Method and limits

The appendix entries and their Status lines were read directly from `audit-blueprint.txt`. Each entry's identity was matched against DECISIONS.md (the findings register and the disposition sections), `phase-5-records.md`, and `phase-5-exit-reconciliation.md` (Obs). Entries whose identity did not match were searched by substance over the same sources (Obs). Limits: the substance search is word-based and can miss differently-worded coverage, so "not located" is not "proved absent"; an appendix entry title is not by itself an established finding ID; and each not-located entry's classification needs its own identity or substance match and a historical supersession check (Inf). This record performs no such classification.

## Result: 18 entries

Of the 18 appendix entries: 3 agree with the current records, 12 are Candidate entries superseded by later records whose current words stand in the named sources, and 3 were not located in the named sources by this bounded search (Obs).

### Agree with the current records (3)

| Appendix entry | Appendix status (verbatim) | Current record |
| --- | --- | --- |
| F17 | "Status: Rejected" | DECISIONS.md register: Rejected |
| F18 | "Status: Rejected" | DECISIONS.md register: Rejected |
| F19 | "Finding status: Fixed, historically (DECISIONS.md F19, PR #42). Reverification under this audit is pending; no current verification is claimed here." | This appendix entry is itself the current governing record; the register's Settled is historical |

### Superseded by later records (12)

| Appendix entry | Appendix status (verbatim) | Current record |
| --- | --- | --- |
| F20 | "Status: Candidate pending independent reproduction" | Confirmed Defect (source argument), `phase-5-exit-reconciliation.md`, section 1 |
| F21 | "Status: Candidate pending R1 and independent reproduction" | Confirmed Defect (injected scope), `phase-5-records.md`, section 3B (D74) |
| F22 | "Status: Candidate pending R3 and independent reproduction" | Not Reproduced, `phase-5-records.md`, section 3B (D74, D75) |
| F23 | "Status: Candidate pending independent reproduction" | Confirmed Defect, `phase-5-records.md`, section 3B (D73) |
| F24 | "Status: Candidate pending R4 and independent reproduction" | Confirmed Defect (source argument plus qualified historical reproduction), `phase-5-exit-reconciliation.md`, section 1 |
| Q1 | "Status: Candidate pending R1" | Reverified (injected scope), `phase-5-exit-reconciliation.md`, section 1 |
| Q2 | "Status: Candidate pending R1" | Reverified (injected scope), `phase-5-exit-reconciliation.md`, section 1 |
| Q3 | "Status: Candidate pending R1" | Confirmed Defect (injected case), `phase-5-records.md`, section 2 (D67) |
| L1 | "Status: Candidate. Evidence Gap: open." | Not Reproduced, `phase-5-records.md`, section 2 (D69) |
| N1 | "Status: Candidate, potentially folded into F20" | Rejected, `phase-5-records.md`, section 3B (D74, D75) |
| P7 | "Status: Candidate pending R5" | Rejected, `phase-5-records.md`, section 3B (D74, D75) |
| S5 | "Status: Candidate pending reproduction" | Reproduced (rows 5, 10, 61), `phase-5-records.md`, section 2 (D68) |

### Not located by this bounded search (3)

No finding row was located for these three entries (Obs; the word-based search limit of the method section applies):

| Appendix entry | Appendix status (verbatim) |
| --- | --- |
| Score | "Status: Candidate. Evidence Gap: possible." |
| Scheduler fault cases | "Status: Candidate; classification depends on the O6 trust ledger." |
| Entry-wrapper cases | "Status: Candidate pending boundary inspection" |

## The three entries not located

**Score.** The entry says that replacing `Number.isSafeInteger(score)` with `Number.isInteger(score)` in a scratch mutation permits unsafe integer scores, and that if the permanent suite does not detect the weakened predicate, the result is primarily a test-strength evidence gap unless a requirement violation is separately established; whether unsafe integers are valid scores is R1's question.

**Scheduler fault cases.** The entry's classification depends on the O6 trust ledger. The named sources carry scheduler trust as assumption records (F5, D2, D22 T3), not as a finding row for these cases (Obs).

**Entry-wrapper cases.** The entry records a concrete observation - at 30e0085, `softDrop` sets `isConfirmingNewGame = false` before calling the guard, and the previous audit's statement that all three public wrappers contain only the guard call was wrong for `softDrop` - and remains a candidate pending boundary inspection (Obs). An observation recorded in a candidate entry is not a finding classification (Inf).

## What this record does not do

- It adopts no status word and closes nothing; all register states and current records are unchanged.
- It does not classify the three not-located entries, does not add them to the crosswalk's 53-ID roster, and does not adopt any new roster or universe count.
- It does not resolve whether the crosswalk's named-source union covers every finding the exit criterion means; it records one appendix sweep as grounding for that open question.
- It names no new audit phase, gate, or owner decision.
