# Decision Text and Supporting Notes

The decision rules the audit uses, separate from supporting notes.

Status and provenance are recorded in `DECISIONS.md`, row D35. The drafter read production code, so this record is not implementation-independent under blueprint O8. No restatement below was taken from code or tests.

Purpose: the blueprint requires each Phase 1 decision to be recorded as normative text without code locations, test names, observed implementation behavior or finding history. Some governing decision files carry such material next to their decision text. Historical files are not edited. This record says which parts of each governing file are the normative decision text, which parts are annotations outside it, and restates in code-free form the two decisions whose text names code. It adds no behavior and changes no decision.

## 1. What counts as normative decision text

For each governing file listed in `docs/phase-1-record-index.md` (deleted, kept in git history), the normative decision text is the numbered or lettered decision statements (for example R1 predicates B1 to B17; R2 to R5 statements S1 onward; T1 to T3; U1 to U4; V1 to V3; W1 to W3 and W5; X1 to X2; K1 to K4 as restated in section 2; Z1; the operation assignments and choices C1 to C4 and E1 to E3). Everything else in a governing file is an annotation: status lines, baseline lines, "Not decided here" and "What is still not specified" sections, provenance notes, and the lines named in section 3. Annotations are not decision text and are excluded from any model input pack built under blueprint O8. The ledger in `DECISIONS.md` governs provenance and approval; no annotation changes it.

## 2. Code-free restatements

These restate, without any file name, constant name or code location, decisions that D27 and D29 recorded with such references. Where the restatement and the earlier wording differ, only the restatement is normative text. Each restates the same behavior already approved in the cited exchange.

**K2 restated (D29).** The audit tests forward and backward clock jumps wherever time decides whether something is cleaned up or loaded. That includes how long the previous offline version of the game is kept after an update, and the requirement that a page never mixes two versions (APP-2). A clock jump is never treated as proof that an old version is safe to delete.

**W4 restated (D27).** The browser features the game depends on are: the 2D drawing surface, including the display color space option the game requests; the animation-frame callback; the Gamepad interface and its connect and disconnect events; the Screen Wake Lock interface; the size and resolution observers and queries used to fit the display; the modal dialog element; page visibility and its event; keyboard and window blur events; the active-element query. Features already decided elsewhere are unchanged: local storage (D23 U1), the four timer calls (D22 T3, D23 U3 and U4), the browser cache on success (D24 V1) and the random source (D24 V3). Service worker registration and the service worker's network requests are decided by D28, and the clock by D29. A browser feature not named here or in those decisions is not trusted. The list names features by what they do and is not a requirement.

## 3. Annotations outside the decision text

- D27: the sentence in W4 beginning "Read from the production files" with its file names, and the file and constant names in the third bullet. Superseded by section 2 for normative purposes.
- D29: the parenthetical in K2 naming a source file and a constant. Superseded by section 2.
- D21 (final bullet), D22, D23 (final bullet), D33 and D34 ("Not decided here" sections): the sentence that some decisions "may differ from how the code behaves today". It is a statement about the implementation, not a decision, and is not part of any model input.
- Every status line, baseline line and provenance sentence stating that the drafter read production code or naming a commit.

## 4. Classification of Phase 1 decisions

| Class | Meaning | Records |
| --- | --- | --- |
| Owner-Approved Behavior | The owner answered specific choice questions; private source proof is retained separately | D16-to-D18, D20-to-D25 and D27-to-D34 decision statements; D15's specific scope approval was independently checked |
| Sourced Consequence | Follows from an approved statement and the cited source; not separately approved | D32 Part A, D33 and D34 E3, the "sourced consequence" clauses named in their rows |
| Annotation | Not decision text | section 3 |

No decision in this class table was found without an owner reply behind its behavioral statement. D30 is a reading of DSP-5 recorded under D25 row 9 and does not edit `REQUIREMENTS.md`.

## Not decided here

- Any change to `REQUIREMENTS.md`, any code change and any model input pack.
- Closure of any Phase 1 exit item.
