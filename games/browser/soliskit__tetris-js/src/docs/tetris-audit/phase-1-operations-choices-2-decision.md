# Touch Movement and Held Controls

When a touch counts as a tap, and what happens to controls held when play resumes.

Status and provenance are recorded in `DECISIONS.md`, row D34. The drafter read production code, so this record is not implementation-independent under blueprint O8. No rule below was taken from code or tests.

Baseline: D31 (frame principle Z1), D32 (`docs/phase-1-operations-record.md`) and D33 (`docs/phase-1-operations-choices-decision.md`), whose "What is still not specified" section listed the two points answered here. This file changes no bytes of any of them and does not edit `REQUIREMENTS.md`. Operation names and item numbers are those of D32.

## Decision text

**E1. Touch excursion (completes D33 C2).** A touch is a tap only if it never moved beyond 10 px from where it started and ends within 10 px of where it started (INP-5). A touch that moved beyond 10 px at any time during the gesture is not a tap, even if it returns to within 10 px of its start, and it commits no rotation. Sourced consequence, not a separate choice: the moves and soft drops the gesture already committed under operation 8 stay committed, because no source undoes a committed operation (D16 section 4); the gesture state (item 14) returns to none when the touch ends (B12).

**E2. Held controls on resume (extends D33 C3).** The rule of D33 C3 applies to every control that repeats under INP-2 and INP-4: a direction key, a held soft drop (S or Down), a gamepad stick direction and a directional pad direction. If such a control is still held when the game resumes, it does not repeat until it is released and pressed again.

**E3. Sourced consequences of C3 and E2 (not choices).** A control held at the moment of resume, including one pressed during the pause (STA-2: no input while paused), does not repeat until released and pressed again. Releasing a different, newer control does not make it repeat again; INP-2's return to a still-held direction does not apply to it. A control pressed after resume behaves as INP-2 says, with the newest-direction rule applied among those. How the held-direction tokens (item 12) are represented to produce this behavior is not decided and is left to the implementation.

## Not decided here

- Closure of the Phase 1 exit item on operations (blueprint O1) or of any other exit item. After D33 and this file, no point listed in D32 Part B remains unspecified; whether the blueprint's O1 exit text is met is reviewed in the closure row, not claimed here.
- Any change to REQUIREMENTS.md and any code change. E1 to E3 may differ from how the code behaves today; that is a later separate decision with its own tests and approval.
