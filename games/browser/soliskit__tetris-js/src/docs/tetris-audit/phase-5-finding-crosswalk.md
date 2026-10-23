# Finding crosswalk of the named Phase 5 sources

Read-only record. No code, test, requirement or CI change. Prepared by the auditor; enters the repository through the usual docs review gates.

One row per unique finding in the union of the named sources: the DECISIONS.md findings register (two tables, 39 rows), the Phase 5 records (`phase-5-records.md`, sections 2, 3A and 3B), and the Phase 5 exit reconciliation (`phase-5-exit-reconciliation.md`, section 1). That union holds 53 unique findings: 40 carry a recorded status word from blueprint section 5.1, 4 (F33, F34, F35, F37) carry this crosswalk's proposed mappings from defect-confirmation narratives (not adopted status words), 8 have no section 5.1 mapping, and F19 has no section 5.1 mapping in these sources but carries a current status record (Fixed, historically; reverification pending) in the blueprint's per-finding appendix, which sits outside this union (section 3). F19 was already one of these 53 inventoried findings, so the appendix shows the named sources' evidence coverage was incomplete - a governing status record lived outside them - while whether the 53 IDs cover every finding the exit criterion means remains a separate, unresolved question; this record changes no status, and the 8 unresolved rows keep their current register states.

The register's own legend defines Open, Pending work and Settled as decision-workflow states ("no decision made", "decided, not yet done", "decided, nothing left to do"), not section 5.1 finding states. Where a later governing record carries a finding's current word, the register column is historical for that finding; DECISIONS.md ("Phase 4 register migration and correction preparation") records that existing individual dispositions remain governing. The register's Rejected definition ("no defect (untrue, or true and harmless, unreachable, or intended)") matches section 5.1's Rejected ("the concern was evaluated and does not violate the applicable requirement or adopted property"), so register Rejected rows carry a section 5.1 state. F21, F22 and F23 are not register rows; their words live in the Phase 5 records only (D72 to D75). F28's two parts are the register's F28a (TE1) and F28b (TE2). D68, named in the certification record's defect note, is a decision row, not a finding.

## 1. Findings with a recorded section 5.1 word or a crosswalk narrative mapping (44)

Of these 44, 40 carry a literal section 5.1 status word in a current record. Four (F33, F34, F35, F37) carry defect-confirmation narratives in DECISIONS.md; their section 5.1 state shown below is this crosswalk's mapping, not an adopted status word. F33, F34 and F35 are corroborated as confirmed defects by the certification record (the STA-2 and INP-2 rows and its defect note); F37's mapping rests on its disposition narrative alone.

| Finding | Also known as | Current word (verbatim) | Source of the word | Section 5.1 state | Register state |
| --- | --- | --- | --- | --- | --- |
| F3 | | Rejected | DECISIONS.md register | Rejected | Rejected |
| F4 | | Rejected | DECISIONS.md register | Rejected | Rejected |
| F5 | | Rejected | DECISIONS.md register | Rejected | Rejected |
| F6 | | Rejected | DECISIONS.md register | Rejected | Rejected |
| F7 | | Rejected | DECISIONS.md register | Rejected | Rejected |
| F9 | | Rejected | DECISIONS.md register | Rejected | Rejected |
| F11 | | Rejected | DECISIONS.md register | Rejected | Rejected |
| F12 | | Rejected | DECISIONS.md register | Rejected | Rejected |
| F15 | | Rejected | DECISIONS.md register | Rejected | Rejected |
| F17 | | Rejected | DECISIONS.md register | Rejected | Rejected |
| F18 | | Rejected | `phase-5-exit-reconciliation.md`, section 1 | Rejected | Rejected |
| F30 | | Rejected as a defect | `phase-5-records.md`, section 3B (D72) | Rejected | Rejected |
| F31 | | Rejected as a defect | `phase-5-records.md`, section 3B (D72) | Rejected | Rejected |
| F32 a | | Rejected | `phase-5-records.md`, section 3B | Rejected | Rejected |
| F32 d | | Rejected | `phase-5-records.md`, section 3B | Rejected | Rejected |
| N1 | | Rejected | `phase-5-records.md`, section 3B (D74, D75) | Rejected | not a register row |
| P7 | | Rejected | `phase-5-records.md`, section 3B (D74, D75) | Rejected | not a register row |
| F20 | | Confirmed Defect (source argument) | `phase-5-exit-reconciliation.md`, section 1 | Confirmed Defect | Pending work |
| F21 | | Confirmed Defect (injected scope) | `phase-5-records.md`, section 3B (D74); same word in `phase-5-exit-reconciliation.md`, section 1 | Confirmed Defect | not a register row |
| F23 | | Confirmed Defect | `phase-5-records.md`, section 3B (D73); same word in `phase-5-exit-reconciliation.md`, section 1 | Confirmed Defect | not a register row |
| F24 | | Confirmed Defect (source argument plus qualified historical reproduction) | `phase-5-exit-reconciliation.md`, section 1 | Confirmed Defect | Pending work |
| F26 | | Confirmed Defect | `phase-5-records.md`, section 3B (D72) | Confirmed Defect | Pending work |
| F27 | | Confirmed Defect | `phase-5-records.md`, section 3B (D72) | Confirmed Defect | Pending work |
| F28 TE2 | F28b | Confirmed Defect (synthetic event) | `phase-5-records.md`, section 3B | Confirmed Defect | Pending work |
| F32 b | | Confirmed Defect | `phase-5-records.md`, section 3B (unchanged) | Confirmed Defect | Pending work |
| F32 c | | Confirmed Defect | `phase-5-records.md`, section 3B | Confirmed Defect | Pending work |
| F33 | | a conditional source-argument defect | DECISIONS.md, "Held soft drop after resume: ordinary callback disposition"; named as a confirmed defect in `phase-5-certification-record.md` (INP-2 row; defect note) | Confirmed Defect (mapping) | Pending work |
| F34 | | a conditional source-argument defect | DECISIONS.md, "Paused count15 Resume disposition"; `phase-5-certification-record.md`, STA-2 row: "a confirmed defect, F34" | Confirmed Defect (mapping) | Pending work |
| F35 | | "rests on an independently reviewed conditional source argument that confirms the narrow U4 stopped-resource defect" | DECISIONS.md, "Ordinary Pause: held soft-repeat resource remains outstanding"; named as a confirmed defect in `phase-5-certification-record.md` (defect note) | Confirmed Defect (mapping) | Pending work |
| F36 | | Confirmed Defect | `phase-5-records.md`, section 3B (D72) | Confirmed Defect | Pending work |
| F37 | | a conditional source-argument defect | DECISIONS.md, "Failed withdrawal: ordinary Continue availability disposition" | Confirmed Defect (mapping) | Pending work |
| Q3 | | Confirmed Defect (injected case) | `phase-5-records.md`, section 2 (D67) | Confirmed Defect | not a register row |
| Row 4 | | Confirmed Defect | `phase-5-records.md`, section 2 (D70) | Confirmed Defect | not a register row |
| F22 | | Not Reproduced | `phase-5-records.md`, section 3B (D74, D75); same word in `phase-5-exit-reconciliation.md`, section 1 | Not Reproduced | not a register row |
| L1 | | Not Reproduced | `phase-5-records.md`, section 2 (D69) | Not Reproduced | not a register row |
| Row 7 | | Not Reproduced (limit approved) | `phase-5-records.md`, section 2 | Not Reproduced | not a register row |
| S5 | | Reproduced (rows 5, 10, 61) | `phase-5-records.md`, section 2 (D68) | Reproduced | not a register row |
| Row 68 | | Reproduced (limit approved: device part untested) | `phase-5-records.md`, section 2 | Reproduced | not a register row |
| Q1 | | Reverified (injected scope) | `phase-5-exit-reconciliation.md`, section 1 | Reverified | not a register row |
| Q2 | | Reverified (injected scope) | `phase-5-exit-reconciliation.md`, section 1 | Reverified | not a register row |
| F25 | | Fixed | `phase-5-records.md`, section 3B (unchanged) | Fixed | Settled |
| F29 | | Folded into F20 | `phase-5-records.md`, section 3B (D72) | Folded into F20 | Pending work |
| F32 e | | Closed (historical note) | `phase-5-records.md`, section 3B | Closed (historical note) | Settled |
| Row 26 | | Candidate, under its approved limit (D78) | `phase-5-records.md`, section 2 | Candidate (the one exception the exit rule allows, D78) | not a register row |

## 2. Findings whose section 5.1 status-word mapping is unresolved (8; register states unchanged)

| Finding | Register state (verbatim) | What is missing |
| --- | --- | --- |
| F1 | Settled | No section 5.1 word in any current record |
| F2 | Settled | No section 5.1 word in any current record |
| F8 | Open | No decision and no section 5.1 word in any record; a Mac-only key report the register says cannot be reproduced off a Mac, on a platform the game does not support |
| F10 | Settled | No section 5.1 word in any current record |
| F13 | Settled | No section 5.1 word in any current record |
| F14 | Settled | No section 5.1 word in any current record |
| F16 | Settled | No section 5.1 word in any current record |
| F28a | F28 TE1; Settled | No section 5.1 word in any current record |

This record proposes no word for any of the 8. The Settled rows are not one case: F10's earlier disposition is "Resolved, No Change" (the surviving mutant was harmless; no repair), F13 and F14 were test-coverage gaps that gained tests, and F1, F2, F16 and F28a record repairs. Each of the 8 needs its own evidence-based reconciliation. Whether the exit criterion's "every finding" covers these pre-blueprint register rows, and what F8's disposition is, are not decided here.

## 3. Finding whose current status record sits outside the named union (1)

F19 has no section 5.1 word in the union sources - `phase-5-exit-reconciliation.md`, section 1 restates it as "Settled (fixed historically)", which is not a section 5.1 state - but the blueprint's per-finding appendix, outside this union, carries its current status record:

| Finding | Also known as | Current word (verbatim) | Source of the word | Section 5.1 state | Register state |
| --- | --- | --- | --- | --- | --- |
| F19 | | "Finding status: Fixed, historically (DECISIONS.md F19, PR #42). Reverification under this audit is pending; no current verification is claimed here." | `audit-blueprint.txt`, per-finding appendix (outside the named union) | Fixed, historically; reverification pending | Settled |

Its register state (Settled) is unchanged. The appendix record governs F19 because no later record contradicts it; this is an entry-level observation, not appendix-wide authority. Sections 1, 2 and 3 account for all 53 findings of the union, one row per finding: 44 + 8 + 1.

## 4. Recorded-Candidate sweep

Within the named sources, item 26 of the findings list ("Row 26" above; not a DECISIONS.md register row) is the only finding recorded as Candidate, and the register notes that earlier labels quoted in rows are history, not statuses. For context outside the named union, not as part of this sweep: D71 (October 17) records that the owner closed Phase 4 with rows 7 and 26 as Candidates under approved limits, and row 7's Candidate was superseded by Not Reproduced (limit approved); the Phase 3 records use the word for non-finding checks. Neither outside use assigns a current finding state. A sweep of the named sources is not a proof that no unrecorded Candidate exists.
