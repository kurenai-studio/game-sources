# Operation Choices

The selected save timing, cancelled-touch behavior, and held-key rule.

Status and provenance are recorded in `DECISIONS.md`, row D33. The drafter read production code, so this record is not implementation-independent under blueprint O8. No rule below was taken from code or tests.

Baseline: D31 (frame principle Z1) and D32 (`docs/phase-1-operations-record.md`), whose Part B left four points unspecified. This file changes no bytes of either and does not edit `REQUIREMENTS.md`. It answers the points of D32 Part B in the order below. Operation names and item numbers are those of D32.

## Decision text

**C1. Line-clear save (D32 Part B point 2).** When clearing lines causes a save (STA-4), the save captures the completed turn: the state after the lock transition has finished, including the next piece having appeared. If that turn ends the game (STA-3), no save is written for it, and the saved game is withdrawn from Continue (S1, S2).

**C2. Touch rotation (D32 Part B point 1).** A touch rotates the piece only when it ends within 10 px of where it started (INP-5). The rotation is committed by operation 9, touch end. A cancelled touch commits no rotation. The gesture state (item 14) still returns to none when a touch ends or is cancelled (B12); C2 concerns only the rotation.

**C3. Resume with a direction still held (D32 Part B point 3).** If a direction key is still held when the game resumes, repeating waits until that key is released and pressed again. Resuming does not by itself move the piece.

**C4. Continue and item 16 (D32 Part B point 4).** Continue does not change item 16. This is the reading of the wording of D21 S9, which lists only withdrawal or its attempt, session start and this session's successful save as changing item 16; it is not an owner choice.

## What is still not specified

- C2 uses the owner's wording "ends within 10 px of where it started". Whether a touch that moved beyond 10 px during the gesture and then ended within 10 px of its start counts as a tap, and whether the pieces it already moved or dropped stay moved, is not stated by INP-5 or by the owner's wording.
- C3 states what repeating does. It does not state how the held-direction tokens (item 12) and the newest-direction order are kept while the key stays held across the pause.
- Anything else in D32 not listed above is unchanged.

## Not decided here

- The points under "What is still not specified".
- Closure of the Phase 1 exit item on operations (blueprint O1) and of any other exit item.
- Any change to REQUIREMENTS.md and any code change. C2 and C3 may differ from how the code behaves today; that is a later separate decision with its own tests and approval.
