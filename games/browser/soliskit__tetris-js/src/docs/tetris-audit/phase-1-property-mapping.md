# Audit Properties and Requirements

Which requirements apply to each audit check, and where they conflict.

Status and provenance are recorded in `DECISIONS.md`, row D25. The drafter read production code, so this record is not implementation-independent under blueprint O8. No entry below was taken from code or tests.

Purpose: the Phase 1 exit criteria ask that the adopted security properties are recorded, that the applicable requirements for each proof obligation are identified, and that conflicting, ambiguous or apparently inconsistent requirements are identified and resolved. This file does that and nothing more. It decides no new behavior, closes no Phase 1 exit item and certifies nothing. The evidence method and certification status columns of the requirement-scope table stay empty (Phases 3 and 5).

## 1. Adopted properties

The properties are O1 to O8 as the blueprint (`docs/audit-blueprint.txt`) states them. The blueprint says they are security properties adopted by the project owner for this audit, and D9 in `DECISIONS.md` records that the audit follows the blueprint as approved by the owner. This file restates none of them. Where the blueprint text and this file differ, the blueprint governs.

## 2. Applicable requirements by obligation

"Applicable" means the requirement text bears on the obligation, so the obligation's proof must account for it. The lists are a Phase 1 identification. They are not an evidence mapping (Phase 3) and they do not say the requirement is established.

| Property | Applicable requirements | Phase 1 decisions that shape it |
| --- | --- | --- |
| O1 Authoritative transition boundary | PCE-6, STA-1, STA-2, STA-3, SAF-3, SAF-4 | D16, D17, D20 |
| O2 Valid transitions only | PCE-1, PCE-3, PCE-4, PCE-6, PLY-1, PLY-3, PLY-4, PLY-6, PLY-7, SCO-1, SCO-2, STA-1, STA-2, STA-3, SAF-4, SAF-6 | D16, D17, D18, D23 (U4) |
| O3 Validated persisted state | SAF-1, SAF-2, STA-4, STA-6, SCO-3 | D18, D21 (S7, S8, S11) |
| O4 Persistence ordering | STA-1, STA-3, STA-4, SAF-2, SAF-3 | D21, D22, D23 (U1) |
| O5 Code-to-claim link | QA-1, QA-2, QA-3, QA-6 | none |
| O6 Trust ledger | SAF-2, SAF-3, SAF-5, STA-6, PCE-5, APP-2, APP-3, APP-6 | D22, D23, D24 |
| O7 Boundary enforcement | SAF-3, SAF-4, PCE-6 | D16, D20, D23 (U4) |
| O8 Independent executable reference model and correspondence | none: no requirement text prescribes it; the blueprint adopts it | none |

The requirement list for O3 includes SCO-3 for the stored high score, whose goodness is decided under R4 and is not restated here. The lists are identified from the requirement text and the blueprint wording for each property and are open to correction by later phases.

## 3. Conflict register

Each row names a tension between requirement texts, or between a requirement and a decision, and how it stands. Rows marked resolved are settled by an existing owner decision. No row creates a requirement.

| # | Tension | Status | Where settled |
| --- | --- | --- | --- |
| 1 | STA-3 "the saved game is forgotten" at game over against SAF-3 "the last good save is kept" on a fault | Resolved: different triggers | D21 S2, S3 |
| 2 | "Forgets the saved game" (STA-1, STA-3, SAF-1) read as deletion | Resolved: forgetting is withdrawal from Continue | D21 S1 |
| 3 | SAF-3 "no timers running" against a timer whose cancellation fails | Resolved for that case by the owner's interpretation | D23 U3 |
| 4 | SAF-3, SAF-4 and STA-3 "timers" against the drawing and polling loops that SAF-5 keeps running | Resolved: timer scope | D23 U4 |
| 5 | "Reported" in SAF-3 and SAF-5 undefined | Resolved: two criteria | D22 T1, D23 U2 |
| 6 | SAF-2 "storage never stops the game" against SAF-3 "if anything throws the game stops" | Resolved: storage failure does not stop gameplay | D21 S4 to S7, D23 U1 |
| 7 | PLY-2 gravity interval against the timer delay the browser actually uses | Resolved: judged on the requested delay | D21 S10 |
| 8 | STA-4 "restores exactly what was saved" against hand-edited or damaged saves | Resolved: accepted whole or rejected whole | D18, D21 S11 |
| 9 | DSP-5 "buttons ... always match the game state, including changes made in another tab" against D21 S9, where a tab that has withdrawn a saved game keeps Continue unavailable even if another tab then saves | Resolved by owner decision: the D21 S9 limit stays, as a narrow exception to DSP-5's wording for Continue availability only. DSP-5's other display obligations are unchanged. REQUIREMENTS.md is not edited and the class of any later requirement edit is not decided. | D25 (owner reply shown the conflict) |

## Not decided here

- Whether the DSP-5 exception needs a REQUIREMENTS.md edit.
- Closure of any Phase 1 exit item. The remaining exit items are the requirement mapping to proof obligations beyond the identification above, the Phase 1 closure checklist and the owner's approval of the Phase 1 decisions.
- Any change to REQUIREMENTS.md and any code change.
- Any evidence method, certification status or finding. Candidate findings noted while drafting belong to Phases 3 to 5.
