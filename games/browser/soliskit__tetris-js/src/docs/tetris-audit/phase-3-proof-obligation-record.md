# Requirement Evidence Records

Interim records for all 55 requirements, not Phase 3 completion.

Status and provenance are in `DECISIONS.md`, row D40. This record cites production code and tests. It must not be given to an O8 model author who needs to stay independent of the implementation. It adds no finding status, certification status, requirement change, or code change.

Base: main. The three partition files preserve the original technical records. P3-C has nontechnical publication redactions. The current publication copies also have title-case status and evidence-field labels. P3-D and P3-E were unedited before that spelling migration. The original records and their source identities remain historical; technical meanings and status assignments are unchanged. The table records original source hashes, not a claim that all current published bytes are unchanged.

## 1. Partition files and requirement coverage

| Partition | Requirement IDs | Count | File | SHA-256 |
| --- | --- | --- | --- | --- |
| P3-C | PCE-1 to PCE-6, PLY-1 to PLY-8, SCO-1 to SCO-3 | 17 | `docs/phase-3-obligations-P3-C.txt` |  |
| P3-D | STA-1 to STA-6, SAF-1 to SAF-6, INP-1 to INP-6 | 18 | `docs/phase-3-obligations-P3-D.txt` |  |
| P3-E | APP-1 to APP-6, DSP-1 to DSP-8, QA-1 to QA-6 | 20 | `docs/phase-3-obligations-P3-E.txt` |  |

The integrator checked that each of the 55 requirement IDs in `docs/phase-1-requirement-scope.md` has exactly one record across the three files, with no ID missing or duplicated, and that each record carries the blueprint 3.3 fields. Every record has the status Candidate or Not Assessed. Candidate means the record can carry evidence and lists its limits. Not Assessed means a stated sub-claim has no method yet. No record is marked certified.

Current published P3-C SHA-256 after nontechnical redaction: . Its requirements, properties, transitions, routes, candidate statuses and technical limitations are unchanged.

## 2. What the records state and do not state

- Every model-correspondence cell in the historical partition records remains pending. Those records predate model construction; four subsequent frozen model revisions and their limits are recorded by D41. The model input pack was approved on October 5, 2026 (ledger row D39). No model transition was invented to fill a template.
- Where the model does not apply (outer layer, display, process and tooling claims), the record names the actual independent evidence method.
- The partition readers ran no full test suite, browser, coverage, mutation or device evidence. P3-E ran 19 dependency-free static tests under Node 22 rather than the target Node 26; two server attempts failed for a missing dependency in the reader's environment, which is an environment limit and not an application result. The eight requirements that depend on devices or external installation (APP-1, APP-4, DSP-1, DSP-2, DSP-4, DSP-6, DSP-7, QA-4) remain in scope with their evidence gaps.
- P3-C and P3-D list candidate observations for Phase 4 (P3-C 15, P3-D 18, P3-E 10). None is a finding. Each needs reproduction against the governing text before it can become one.
- Provenance caveat: the P3-D reader took approval status of Phase 1 decisions from the index and the D35 register and did not read the ledger or the owner channel. The ledger rows govern; this record does not restate approval.

## 3. Integrator notes

- D18 B12 keeps one held-control token per physical control (keyboard A and keyboard Left are separate tokens), so the P3-D candidate about key aliasing is grounded in decision text and stays a Phase 4 candidate.
- INP-3's "ignored" modified keys and its "game keys do not trigger the browser's default action" sentence have no Phase 1 reading and no conflict-register row. Recorded as a gap; no reading is chosen here.
- The P3-C and P3-D candidates about the reset count, the lowest row, resume at count 15, Continue restore and item 16 compare production with D17, D18 and D21 text. They are code-versus-decision comparisons for Phase 4 and for model correspondence. They need no new owner decision now.

## 4. Phase 3 exit status

At the October 5, 2026 recording (D40), Phase 3 was still open. This is historical status, not a claim about the current phase. Current phase records are in `DECISIONS.md`. In addition to these records, Phase 3's exit needed the independent model built from the approved pack, its freeze checksum, and differential evidence for the applicable rows. This record closes none of those items.

## Not decided here

- Any finding or certification status, any requirement or scope change, any code change.
- Closure of Phase 3 or of any Phase 3 exit item.

## Status-label publication migration

Original partition source hashes and earlier disclosure-reduction identities remain historical. The current publication copies have title-case status and evidence-field labels; technical meanings, all requirement IDs and assigned statuses are unchanged. Current hashes are recorded in the migration receipt, not substituted for original reader inputs.
