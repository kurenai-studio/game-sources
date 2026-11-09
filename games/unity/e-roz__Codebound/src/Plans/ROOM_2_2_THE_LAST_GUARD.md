# Plan: Room 2.2 "The Last Guard" (off-by-one, IndexOutOfRange)

Status: **PLAN v1 (2026-11-03). Waiting for your check. No code written yet.**
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
Same learning loop as before. All wording is a draft for you to change.

---

## 1. Why this room
Lesson plan Chapter 2, row 2: `<` vs `<=` and `IndexOutOfRangeException`. At work: pagination and batch jobs that skip or crash on the last record. Same engine as 2.1 (text rows in the Keep frame); only one small addition.

## 2. The room
**Ticket:** "The roll call calls all three guards, then crashes."
**Goal text:** "Call every guard once. Never go past the last one."
```csharp
1  string[] g = {"Ana","Ben","Cy"};
2  int n = g.Length;
3  for (int i = 0; i <= n; i++)
4      Console.WriteLine(g[i]);
```
(4 lines, all under 35 characters. No support-code box.)

**Predict:** "What happens when this runs?" Options: `Prints Ana, Ben, Cy`, `Prints Ana, Ben, Cy, then crashes`, `Crashes before printing anything`, `Prints nothing`. Correct: **Prints Ana, Ben, Cy, then crashes**.
(Trap: the first option. The names print fine, so students think it works.)

**Trace (new picture, text rows like 2.1):**
| Step | Rows after it |
|---|---|
| line 1 | `g = [Ana, Ben, Cy]` |
| line 2 | `n = 3` |
| line 3/4, i = 0 | `i = 0`, prints Ana |
| i = 1, i = 2 | `i = 1` prints Ben, `i = 2` prints Cy |
| i = 3 | `i = 3`, `i <= n is true` |
| line 4 | `g[3]: slots are 0 to 2` → **IndexOutOfRangeException** |

Output shows Ana, Ben, Cy and then the red error (same as the crash in Room 1.5).

**Investigate (watch list):** `g = [Ana, Ben, Cy]`, `n = 3`, `i = 3`, `g has slots 0 to 2`.

**Hypotheses ("Why does it crash?"):**
- A. "g is empty." — Wrong (it printed three names).
- B. "The loop runs one time too many." — Close ("Yes, but why? Look at the condition on line 3.")
- C. **"i <= n lets i reach 3, but the last slot is 2."** — Correct.

**Fix options:**
| Option | Change | Quality | Test result |
|---|---|---|---|
| 1 | Change line 3 to: `for (int i = 0; i < n; i++)` | **Best** | Pass: "Ana, Ben, Cy. No crash." |
| 2 | Change line 2 to: `int n = 2;` | Symptom-only | Fail: "Fine for 3 guards, but with 4 guards Cy would be skipped." |
| 3 | Change line 3 to: `for (int i = 1; i <= n; i++)` | Wrong | Fail: "Ana is skipped and it still crashes." |

**Test:** the loop prints every guard once with 3 guards **and** with 4 guards (so the hard-coded `n = 2` fails).
**Debrief:** "Slots are counted from 0, so the last slot is Length - 1. Use `i < Length`. At work: off-by-one is why batch jobs skip or crash on the last record."
**Hints:** (1) "What is the last slot number of g?" (2) "g has 3 guards, so slots are 0, 1, 2." (3) "`<=` lets i reach 3. Use `<`."
**Stars:** same rules as before.

## 3. What is new in the engine
1. **One new trace event:** `IntSet(variable, number)` (like `BoolSet`, but a number). `KeepState` shows number variables in the same rows.
2. **A text-list variable** `g = [Ana, Ben, Cy]`: shown as one row built from a new `ArraySet(variable, items)` event, or I reuse an existing event if one fits. (Decision for me, no visible change.)
3. Output may hold several lines (Ana, Ben, Cy) before the error. I will check that the output text allows this, otherwise print them on one line.
4. **Row count:** 6 rows is enough (g, n, i + a note). No scene change expected. If I need more rows I will tell you first.
5. `RoomLibrary` gets `"2-2"` (the Keep catalog already lists it), tests, Rooms 1.1 to 2.1 stay unchanged (all 212 tests must still pass).

## 4. Build phases
- **A. Core:** new events, KeepState, Room22, library, tests.
- **B. Scene:** play 2.2 from the Keep Map (back up and restore your save), re-check 2.1.
- **C. Playtest:** classmate: "Explain why the loop crashes after printing Cy."

## 5. Risks
- Showing "which loop round we are on" as text rows may feel flat. A small loop counter picture can come later (art).
- Two Chapter 2 rooms in a row use only text rows. Fine for the MVP; the Gate sprite stays an art task.

## 6. Questions for you
1. Guard names Ana / Ben / Cy OK, or do you want Filipino names (Juan, Maria, Pedro)?
2. Is the symptom-only fix (`n = 2`) clear enough, or do you prefer something else?
