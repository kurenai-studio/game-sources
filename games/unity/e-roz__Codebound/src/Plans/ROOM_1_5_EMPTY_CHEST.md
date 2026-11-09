# Plan: Room 1.5 "The Empty Chest"

Status: **PLAN v1 (2026-11-03). Waiting for your check. No code written yet.**
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
Same mechanics as Rooms 1.1 to 1.4. All wording is a draft for you to change.

---

## 1. Why this room
Lesson plan row 1.5 (Bug Hunt): "The machinery crashes opening a `null` chest. `NullReferenceException`; null checks vs masking the problem."
At work: the most common production error.
New idea compared with 1.1 to 1.4: a variable can point to **nothing** (null). Using it crashes. And a quick `if (x != null)` can hide the real bug.

## 2. The room
**Ticket:** "The machinery crashes when it opens the north vault."
**Goal text:** "The Gem ends up in a vault, and the program does not crash."
```csharp
1  Chest vault = FindChest("north");
2  Console.WriteLine("Opening vault");
3  vault.Add("Gem");
```
**Support code box (button "Class code"):**
```csharp
Chest FindChest(string name)
{
    return name == "east" ? east : null;
}
```
(There is no "north" chest, so `FindChest("north")` returns `null`.)

**Predict:** "What happens when line 3 runs?" Options: "The Gem is added to the vault", "The Gem is ignored", "The program crashes with an error", "A new vault is created". Correct: the third one.

**Trace (7 events):**
| Line | Events |
|---|---|
| 1 | LineExecuted(1), VariableDeclared(vault), NullAssigned(vault) |
| 2 | LineExecuted(2), Output("Opening vault") |
| 3 | LineExecuted(3), ExceptionThrown(NullReferenceException) |

**Investigate (watch list):** `vault -> null`. The Keep shows the guard "vault = null" and no chest.

**Hypotheses ("Why does the program crash?"):**
- A. "Line 2 sets vault to null." — Wrong (line 2 only prints).
- B. "Line 3 is the broken line." — Close ("That is where it crashes, but not why. Ask what vault holds when line 3 runs.").
- C. **"FindChest returned null, so vault points to nothing when line 3 uses it."** — Correct.

**Fix options:**
| Option | Change | Quality | Test result |
|---|---|---|---|
| 1 | Add after line 1: `vault = vault ?? new Chest();` | **Best** | Pass: "vault exists and holds 1 item." The missing chest is created, then the Gem goes in. |
| 2 | Change line 3 to: `if (vault != null) vault.Add("Gem");` | Symptom-only (masking) | Fail: "No crash, but vault is still null and the Gem was never stored. The null check only hid the problem." |
| 3 | Change line 1 to: `Chest vault = FindChest("south");` | Wrong | Fail: "Line 3 threw a NullReferenceException. FindChest(\"south\") returns null too." |

**Test:** `vault` is not null and `vault.Count == 1`.
**Debrief:** "Calling a method on null throws NullReferenceException. A null check that just skips the code hides the problem: the Gem is lost silently. Decide what should happen when something is missing: create it, or report it. At work: the most common production error." (Shortened after Phase B: the first version did not fit the panel.)
**Hints:** (1) "What does vault hold after line 1?" (2) "FindChest returns null when it finds nothing." (3) "You cannot call Add on null. Decide what should happen instead."
**Stars:** same rules as before.

## 3. What changes in the engine
Almost nothing: the null events already exist from Room 1.1. One wording fix found in Phase B: the Observe text now says "it crashed with NullReferenceException" when the program crashes, instead of "it printed ...".
- `Room15.cs`, `RoomLibrary` gets `"1-5"`, tests.
- The Keep Map already lists 1.5 as "The Empty Chest".
- Existing views already show "vault = null" and the exception text.
- No scene rebuild, no new art. The empty chest is not drawn at all (only the guard "vault = null") **[OPEN]**: an empty-chest or "missing" icon would make this clearer, but that is art work for later.

## 4. Build phases
- **A. Core:** Room15, library, tests (all old tests + new pass).
- **B. Scene:** play 1.5 from the Keep Map (back up and restore your save so progress is not changed); check the Keep looks clear with only one guard and no chest.
- **C. Playtest:** classmate: "Explain why a null check alone is not a good fix here."

## 5. Verification
- Rooms 1.1 to 1.4 behave exactly as before.
- 1.5: verdicts for predict, cause, each fix; auto test; Goal text on Ticket and Fix; stars saved to room 1-5.
- Core has no Unity references; no rule logic in UI scripts.

## 6. Risks
- A screen with one guard and no chest may look empty. Checked in Phase B.
- The `??` operator may be new to students. The fix option text is short and the debrief explains "create it if missing". If it is too hard, the option can become two lines (`if (vault == null) vault = new Chest();`), but that is too wide for the code panel.

## 7. Questions for you
1. Best fix = "create a default chest when it is missing" (recommended: the program keeps working and the Gem is stored). Or do you prefer a different best fix?
2. `??` in the fix: keep it (recommended), or find another wording?
