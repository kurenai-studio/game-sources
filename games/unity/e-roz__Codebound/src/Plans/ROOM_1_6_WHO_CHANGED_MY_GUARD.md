# Plan: Room 1.6 "Who Changed My Guard?" (Interview, end of Chapter 1)

Status: **PLAN v1 (2026-11-03). Waiting for your check. No code written yet.**
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
Same mechanics as Rooms 1.1 to 1.5. All wording is a draft for you to change.

---

## 1. Why this room
Lesson plan row 1.6 (Interview): "A method that modifies a passed-in object vs one that reassigns it. Reference passed by value; mutation vs reassignment."
Favourite interview question. At work: the source of surprising side effects.
It ties the whole chapter together: references (1.1), values (1.2), copies (1.3, 1.4), null (1.5), and now **what a method receives**.

**Interview feel:** the ticket is written as an interviewer's question, and the "pick the cause" step is the "explain why" part of the answer. The loop stays the same.

## 2. The room
**Ticket:** "Interview: Reset should empty the vault, but it still holds the Gem. Explain why."
**Goal text:** "After line 3, the vault is empty."
```csharp
1  Chest vault = new Chest();
2  Fill(vault);
3  Reset(vault);
4  Console.WriteLine(vault.Count);
```
**Class code box (button "Class code"):**
```csharp
void Fill(Chest c)
{
    c.Add("Gem");
}
void Reset(Chest c)
{
    c = new Chest();
}
```
The player opens the box to read the two methods, then closes it to see the main code (same as the Chest class in 1.1).

**Predict:** "What does line 4 print?" Options `0`, `1`, `2`, `An error`. Correct: `1`. (Trap: `0`.)

**Trace (17 events):**
| Line | Events |
|---|---|
| 1 | LineExecuted(1), VariableDeclared(vault), ObjectCreated(#1, Chest), ReferenceAssigned(vault → #1) |
| 2 | LineExecuted(2), VariableDeclared(c), ReferenceAssigned(c → #1), ObjectMutated(#1, "Gem added"), ScopeEnded(c) |
| 3 | LineExecuted(3), VariableDeclared(c), ReferenceAssigned(c → #1), ObjectCreated(#2, Chest), ReferenceAssigned(c → #2), ScopeEnded(c) |
| 4 | LineExecuted(4), Output("1") |

On the Keep: while `Reset` runs, the helper guard `c` first points to chest #1, then to a new chest #2. When Reset ends, `c` disappears. Chest #2 is left alone and `vault` still points to chest #1 (with the Gem). That picture is the whole lesson.

**Investigate (watch list):** `vault -> chest #1`. The Keep shows "Chest #1: Gem" and an empty "Chest #2" that no guard uses.

**Hypotheses ("Why is the vault not empty?"):**
- A. "Reset never runs." — Wrong (it runs on line 3).
- B. "Reset makes a new chest, but the old chest is still full." — Close ("True, but that is not the whole reason. Why does vault not use the new chest?").
- C. **"Reset only changes its own copy of the reference (c), so vault still points to the old chest."** — Correct.

**Fix options:**
| Option | Change | Quality | Test result |
|---|---|---|---|
| 1 | Change line 3 to: `vault = new Chest();` | **Best** | Pass: "vault holds 0 items." Reassign where the variable lives. |
| 2 | Change line 4 to: `Console.WriteLine(0);` | Symptom-only | Fail: "It prints 0, but vault still holds the Gem. You only hid the problem." |
| 3 | Change line 3 to: `Fill(vault);` | Wrong | Fail: "vault holds 2 items. Calling Fill again made it worse." |

**Test:** `vault.Count == 0`.
**Debrief:** "A method receives a copy of the reference. c.Add(...) changes the caller's object. c = new Chest() only changes the copy. To replace the caller's object, assign it where the variable lives. At work: a favourite interview question."
**Hints:** (1) "Does Reset change the chest, or only what c points to?" (2) "c is a copy of the reference. Reassigning c does not change vault." (3) "To change vault, assign to vault itself."
**Stars:** same rules as before.

## 3. What changes in the engine
Small: one new trace event.
1. `TraceEventType.ScopeEnded` (a variable goes away when a method returns). `KeepState` removes that guard and says so in the caption. Tests.
2. `Room16.cs`, `RoomLibrary` gets `"1-6"`, tests.
3. Everything else already exists (support-code box, two guards, two chests, labels).
No scene rebuild, no new art. Rooms 1.1 to 1.5 stay unchanged (all old tests must pass).

**Chapter end:** after 1.6 the Keep Map should show Chapter 1 complete and unlock "The Gates" (the rules already exist). Checked in Phase B. Chapter 2 rooms stay "coming soon".

## 4. Build phases
- **A. Core:** `ScopeEnded`, KeepState, Room16, library, tests.
- **B. Scene:** play 1.6 from the Keep Map (back up and restore your save); check the helper guard `c` appears and disappears clearly; check the Keep Map after chapter completion without changing your real save if possible.
- **C. Playtest:** classmate: "Explain why Reset did not empty the vault." This is the real interview question.

## 5. Verification
- Rooms 1.1 to 1.5 behave exactly as before.
- 1.6: verdicts for predict, cause, each fix; auto test; Goal text on Ticket and Fix; stars saved to room 1-6.
- Core has no Unity references; no rule logic in UI scripts.

## 6. Risks
- The player must open the Class code box to read the methods, so the main code and the methods are not on screen together. If this hurts the prediction, we later widen the code panel (a scene change).
- Two guards (`vault` and `c`) use both guard slots. Fine for this room; a room with three variables would need more slots.
- The helper guard `c` may look like a second guard in the Keep. The caption says "c is a copy of the reference" while it exists.

## 7. Questions for you
1. Is "Reset should empty the vault" a clear story for an interview question?
2. Methods in the Class code box (recommended, no scene change), or do you want the methods shown in the main code panel (needs a bigger panel and a scene rebuild)?
