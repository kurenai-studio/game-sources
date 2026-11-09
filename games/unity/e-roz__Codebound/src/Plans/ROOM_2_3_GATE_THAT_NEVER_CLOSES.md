# Plan: Room 2.3 "The Gate That Never Closes" (infinite while loop)

Status: **APPROVED (2026-11-03) and implemented. Changes from v1 are listed in section 7.**
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
All wording is a draft for you to change.

---

## 1. Why this room
Lesson plan Chapter 2, row 3: a `while` condition that never changes. At work: runaway jobs and timeouts. Same text-row picture as 2.1 and 2.2.

Note: DEVELOPMENT_ROADMAP lists 2.3 as a stretch room and the Keep Map catalog does not have it yet. Building it means adding `"2-3"` to `KeepCatalogSeed` (between 2-2 and 2-4). The lesson plan also says "using breakpoints"; I suggest we do NOT build the Breakpoint tool now. The Investigate step already shows the variables, which does the same job for this room. (Question 3.)

## 2. The room
**Ticket:** "The gate knocks forever. The program never stops."
**Goal text:** "Knock 3 times, then stop."
```csharp
1  int tries = 3;
2  while (tries > 0)
3  {
4      Console.WriteLine("Knock");
5  }
```
(5 lines, all short. No support-code box.)

**Predict:** "What happens when this runs?" Options: `Knocks 3 times, then stops`, `Knocks once`, `Knocks forever`, `Nothing`. Correct: **Knocks forever**.
(Trap: the first option. The goal says 3, and `tries = 3` looks like a counter, but nothing ever changes it.)

**Trace (text rows):**
| Step | Rows after it |
|---|---|
| line 1 | `tries = 3` |
| line 2, round 1 | `step 1: tries > 0 = true` |
| line 4 | prints Knock |
| line 2, round 2 | `step 2: tries > 0 = true`, prints Knock |
| line 2, round 3 | `step 3: tries > 0 = true`, prints Knock |
| end of trace | **Timeout: "Stopped after too many rounds. tries is still 3."** |

The trace shows only 3 rounds, then a stop message (a real program would repeat millions of times). Output: `Knock, Knock, Knock` and then the red stop message.

**Investigate (watch list):** `tries = 3`, `tries > 0 = true (every round)`, `nothing changes tries inside the loop`.

**Hypotheses ("Why does it never stop?"):**
- A. "The loop condition is wrong. It should be tries < 0." — Wrong (that would never even start).
- B. "The loop never ends." — Close ("Yes, but why? What decides when it ends?")
- C. **"tries never changes inside the loop, so tries > 0 stays true."** — Correct.

**Fix options:**
| Option | Change | Quality | Test result |
|---|---|---|---|
| 1 | Add `tries--;` inside the loop | **Best** | Pass: "Knock, Knock, Knock. It stops." |
| 2 | Add `break;` after the print | Symptom-only | Fail: "It stops, but it only knocks once." |
| 3 | Change line 2 to: `while (tries >= 0)` | Wrong | Fail: "tries still never changes. It still never stops." |

**Test:** the loop prints Knock exactly 3 times and then ends.
**Debrief:** "A while loop needs something inside it that moves the condition toward false. Here, tries-- does that. At work: a loop that never ends freezes a service or burns CPU until a timeout kills it."
**Hints:** (1) "Which line changes tries?" (2) "No line changes it, so tries > 0 is true every round." (3) "Add tries--; inside the loop."
**Stars:** same rules as before.

## 3. What is new in the engine
1. **A "ran too long" ending.** I will reuse the existing `ExceptionThrown` event with the text `Timeout: stopped after too many rounds` if the red error line looks right. If it does not, one tiny new event `TimedOut`. (My decision, no visible difference.)
2. Fix options need a line **inserted** (`tries--;`), not only replaced. Rooms so far changed existing lines; the fix code list may have 6 lines instead of 5. I will check the code panel fits (5 to 6 lines).
3. `RoomLibrary` gets `"2-3"`, `KeepCatalogSeed` gets the room button, tests added. Existing tests that say "2-3 is not available" must change to "2-6" (like I did for 2-2).
4. Rooms 1.1 to 2.2 stay unchanged (all 223 tests must still pass).

## 4. Build phases
- **A. Core:** Room23, library, catalog entry, tests.
- **B. Scene:** play 2.3 from the Keep Map (back up and restore your save), check the 6-row panel and the stop message.
- **C. Playtest:** classmate: "Explain why the loop never stops."

## 5. Risks
- A 3-round trace for an "infinite" loop may feel fake. The stop message tries to make that clear ("still 3").
- Unlock order: 2.3 sits between 2.2 and 2.4 in the catalog, so 2.4 would unlock after 2.3. I will check `UnlockRules` so nothing breaks.

## 6. Questions for you
1. Knock / tries example OK, or do you prefer another story (a gate that counts guards, a queue that never empties)?
2. Is the symptom-only fix (`break;`) clear enough?
3. Skip the Breakpoint tool for now and use the Investigate watch list instead? (I recommend yes.)

## 7. Changes made while coding
- The code panel has only 5 rows, so the original is 4 lines (`while (tries > 0) {` with the brace on the same line). The best fix inserts `tries--;` and becomes 5 lines. No scene change needed.
- Timeout reuses `ExceptionThrown` with the text "Timed out (loop never ends)". No new event.
- Catalog: 2-3 added to `KeepCatalogSeed` and `KeepCatalog.asset`. Room 2.4 stays 2-4 but now shows as "2.4" in the map (it was "2.3" before).
- Trace: 15 events (original), 22 (best fix), 6 (break fix). Rows show `tries = 3` and three identical checks `3 > 0 = true`.
- Tests: 9 new in Room23Tests; three count tests updated (5 gate rooms, 11 rooms, 33 max stars).
