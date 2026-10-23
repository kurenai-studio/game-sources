# Phase 5 closure record

Read-only record. No code, test, requirement or CI change. Prepared by the auditor; enters the repository through the usual docs review gates.

Which Phase 5 exit checks are met, which stay open, and the records that support them. The criteria are the Phase 5 line under "Exit criteria for Phases 2 to 10" in `docs/tetris-audit/audit-blueprint.txt` and the numbered exit list in `docs/tetris-audit/phase-5-records.md`, section 6. A check is marked satisfied only where a governing record on `main` states it; no draft or historical review file is relied on for a satisfied mark. The audit's finding crosswalk of the named sources is a supporting draft compiled from `main` sources (the DECISIONS.md findings register, `phase-5-records.md` sections 2, 3A and 3B, and `phase-5-exit-reconciliation.md` section 1); it separates directly verified facts from its own proposed mappings and draws no universal conclusion. The certification record this matrix relies on records that the original evidence copies for batches 6, 7 and 8 are unavailable; their content was reconstructed, independent review passed the reconstructed content, and the original identity of those copies is unconfirmed, so that review covers the reconstruction, not the originals.

## Matrix

| # | Exit check | Governing records | Result |
| --- | --- | --- | --- |
| 1 | Each original finding (F18 to F24, Q1, Q2, N1, P7) is matched against the later decisions that narrowed it | `phase-5-exit-reconciliation.md`, section 1 | Satisfied |
| 2 | Each of the 55 in-scope requirements has one certification status, each property O1 to O8 has one from blueprint section 5.2, and no in-scope property remains Not Assessed | `phase-5-certification-record.md`, requirements table and O1 to O8 table; `phase-1-requirement-scope.md`, Certification status column | Satisfied |
| 3 | Every finding has one finding status | The audit's finding crosswalk of the named sources | Open; see below |
| 4 | No finding remains Candidate except item 26, which may stay Candidate under its approved limit (D78) | The audit's finding crosswalk of the named sources: item 26 of the findings list (`phase-5-records.md`, section 2) is the only finding recorded as Candidate in the named sources; the register notes that earlier labels quoted in rows are history, not statuses | Open: bounded to the named sources; see below |
| 5 | Every Requirement Clarification found in the reconciliation has the owner's yes | `phase-5-exit-reconciliation.md`, section 3: the reconciliation produced none | Satisfied; nothing needed approval |
| 6 | Owner approval where a disposition includes it (the Not Established dispositions) | DECISIONS.md, D79: the owner approved decision sets A and B on October 22, 2026 | Satisfied |

## What stays open

Check 3 (every finding has one finding status). The named-source union holds 53 unique findings. 40 carry a recorded status word from blueprint section 5.1. Four (F33, F34, F35, F37) carry defect-confirmation narratives in DECISIONS.md; their section 5.1 state (Confirmed Defect) is the crosswalk's proposed mapping, not an adopted status word. Eight have no section 5.1 mapping in these sources and keep their register states unchanged: F8 (Open - no decision made; a Mac-only key report on a platform the game does not support) and the seven Settled rows F1, F2, F10, F13, F14, F16 and F28a. The Settled rows are not one case: F10's earlier disposition is "Resolved, No Change" (the surviving mutant was harmless; no repair), F13 and F14 were test-coverage gaps that gained tests, and F1, F2, F16 and F28a record repairs. The union's 53rd finding, F19, has no section 5.1 word in the named sources, but the blueprint's per-finding appendix, outside the named union, records its current status verbatim: "Finding status: Fixed, historically (DECISIONS.md F19, PR #42). Reverification under this audit is pending; no current verification is claimed here." F19's open point is that pending reverification. Each of the twelve - the 4 proposed mappings and the 8 unresolved - needs its own evidence-based reconciliation, and any status-word change enters through the usual gates (the audit's records set status words from runs or source arguments, or the owner chooses them, as `phase-5-records.md`, section 3B records).

Check 4 (no Candidate except item 26). The sweep behind the matrix row is bounded to the named sources; it is not a proof that no unrecorded Candidate exists.

One coverage question sits over checks 3 and 4: whether the named-source union's 53 finding IDs cover every finding the exit criterion means is unresolved, and the blueprint's per-finding appendix, which sits outside the union, already shows the named sources' evidence coverage was incomplete - a governing status record for an already-inventoried finding lived outside them.

## Closure statement

Checks 1, 2, 5 and 6 are recorded as passed. Checks 3 and 4 stay open. This record therefore does not close Phase 5, and no final certification is claimed.

## Not decided here

- The 4 proposed mappings and the 8 unresolved status-word mappings in check 3 (F19's status is already recorded in the blueprint's per-finding appendix, with reverification pending); this record adopts no status word.
- F8's disposition.
- Any fix, including the confirmed defects that stand (the defect-bearing rows the certification record names).
- Any status upgrade from new evidence, including later device evidence for the set-B device, display and Safari halves.
- The INP-7 requirement addition (D70); adding it is a requirement change outside this record.
- Any change to code, tests, requirements or CI.
