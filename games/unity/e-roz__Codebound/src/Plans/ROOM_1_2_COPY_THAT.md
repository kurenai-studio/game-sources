# Plan: Room 1.2 "Copy That"

Status: **PLAN v1 (2026-11-03). Waiting for your check. No code written yet.**
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
Same mechanics as Room 1.1 (Ticket → Predict → Observe → Investigate → Hypothesis → Fix → Prove → Debrief, verdicts, auto test, Goal text, hints, stars).
All wording below is a draft for you to change.

---

## 1. Why this room
Room 1.1 taught: copying an object variable copies the *reference*, so two names share one chest.
Room 1.2 is the opposite: copying an `int` copies the *value*, so the two variables are separate.
A player who just learned 1.1 will wrongly predict that the pouches are shared. That is the trap, and the point.
Lesson plan row: "Copy That. Value types vs references; string immutability."

## 2. The room
**Ticket:** "Guard A's pouch should hold 8 coins after the bonus, but it still holds 5."
**Goal text:** "Guard A ends with 8 coins."
```csharp
1  int coinsA = 5;
2  int coinsB = coinsA;
3  coinsB = coinsB + 3;
4  Console.WriteLine(coinsA);
```
No support-code box needed (only `int`). The "Chest class" button is hidden for this room.

**Predict:** "What does line 4 print?" Options `3`, `5`, `8`, `An error`. Correct: `5`.
(Wrong answer `8` is the 1.1 habit: "they share".)

**Trace (10 events):**
| Line | Events |
|---|---|
| 1 | LineExecuted(1), VariableDeclared(coinsA), ValueSet(coinsA = 5) |
| 2 | LineExecuted(2), VariableDeclared(coinsB), ValueSet(coinsB = 5) |
| 3 | LineExecuted(3), ValueSet(coinsB = 8) |
| 4 | LineExecuted(4), Output("5") |

**Investigate (watch list):** `coinsA = 5`, `coinsB = 8`.

**Hypotheses ("Why does Guard A still have 5?"):**
- A. "Line 3 changes both pouches." — Wrong (it only touches `coinsB`).
- B. "Line 2 makes both guards share one pouch, like the chests." — Close (right line, wrong idea: that is how objects behave, not numbers).
- C. **"Line 2 copies the number, so coinsB is its own pouch and line 3 only changes coinsB."** — Correct.

**Fix options:**
| Option | Change | Quality | Test result |
|---|---|---|---|
| 1 | Line 3 becomes `coinsA = coinsA + 3;` | **Best** | Pass: "coinsA is 8." |
| 2 | Line 4 becomes `Console.WriteLine(8);` | Symptom-only | Fail: "It prints 8, but coinsA is still 5. You hid the problem." |
| 3 | Line 3 becomes `coinsB = 3;` | Wrong | Fail: "coinsA is still 5 and coinsB lost its coins." |

**Test:** `coinsA == 8`.
**Debrief:** "A number variable holds the value itself, so `int b = a;` makes an independent copy. Objects (1.1) hold a reference, so copies share. Know which one you have before you change a copy. At work: changing a copy of a price or a count never changes the original, but changing a copy of an object does."
**Hints:** (1) "Which variable does line 3 change?" (2) "A number is copied as a whole, not shared." (3) "After line 2, coinsA and coinsB are separate."
**Stars:** same rules as 1.1.

## 3. Scope
**Strings:** the lesson plan also lists string immutability. **[OPEN]** Recommended: leave it out of 1.2 and add a short line in the debrief ("strings behave like numbers here"); give it its own room later. You decide.

**What must change in the engine (not just room data):**
1. `TraceEventType`: add `ValueSet`. `KeepState`: remember a number per variable, show it in the guard's pouch. Tests.
2. `RoomDefinition`: move the hard-coded Room 1.1 words into room data: Investigate prompt, Hypothesis prompt, and a flag for "show Chest class box". `RoomFlow` reads them. 1.1 text stays identical (existing tests must still pass).
3. `Room12.cs` (room data), `RoomLibrary` gets `"1-2"`.
4. Room scene builder: guard shows a number label in a pouch; chests, thread and sword hidden when the room has none. Keep view draws only what the state has.
5. Tests: Room12 data, flow, KeepState values, library. Target: all old tests + new ones pass.

**Out:** string room, new art, new UI screens, dialogue.

## 4. Build phases
- **A. Core:** `ValueSet`, KeepState values, RoomDefinition prompts, Room12, RoomLibrary, tests. No Unity visuals.
- **B. Scene:** KeepView pouch label, builder changes, rebuild Room scene, enter from the Keep Map room 1.2.
- **C. Playtest:** play it yourself, then a classmate ("Explain why coinsA stayed 5").

## 5. Verification (check against this plan)
- 1.1 still plays and its text is unchanged.
- 1.2: right/close/wrong verdicts on predict, cause and each fix; test auto-runs; stars saved to room 1-2.
- Goal text shows on Ticket and Fix screens.
- No rule logic in UI scripts; Core has no Unity references.

## 6. Risks
- Moving the 1.1 words into data could break 1.1 text. Mitigation: existing tests stay as they are.
- Number label might not fit the guard sprite. Mitigation: check in Phase B screenshot.

## 7. Questions for you
1. Is "Guard A should hold 8" a clear enough story, or do you want a different ticket?
2. Strings: leave out of 1.2 (recommended), or include?
