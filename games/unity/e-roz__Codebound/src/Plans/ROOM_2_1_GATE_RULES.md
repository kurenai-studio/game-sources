# Plan: Room 2.1 "The Gate Rules" (first room of Chapter 2)

Status: **APPROVED (2026-11-03). Implemented; note BoolSet declares the variable itself, so the trace has 12 events.**
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
Same learning loop as Chapter 1 (Ticket → Predict → Observe → Investigate → Hypothesis → Fix → Prove → Debrief, verdicts, auto test, Goal text, hints, stars). All wording is a draft for you to change.

---

## 1. Why this room, and why it is different
Lesson plan row 2.1 (Predict): "The wrong visitors get in. `&&` / `||` precedence, parentheses." At work: access-control and permission bugs.
Chapter 1 showed **objects in memory** (guards, chests). Chapter 2 is about **decisions**, so the Keep needs a new picture: a **gate that checks a rule step by step**. Rooms 2.1, 2.2, 2.4 and 2.5 in the Keep Map are the Chapter 2 MVP (2.3 and 2.6 come later).

## 2. The room
**Ticket:** "A member with no pass walked into the vault."
**Goal text:** "Everyone needs a pass. Members and guests both get in with one."
```csharp
1  bool member = true;
2  bool guest = false;
3  bool pass = false;
4  bool ok = member || guest && pass;
5  Console.WriteLine(ok);
```
No support-code box (only `bool`).

**Predict:** "What does line 5 print?" Options `True`, `False`, `An error`, `Nothing`. Correct: `True`.
(Trap: reading left to right gives `(true || false) && false` = False. But `&&` goes first.)

**Trace (12 events), new picture, see section 3:**
| Line | Events |
|---|---|
| 1 | LineExecuted(1), BoolSet(member = true) |
| 2 | LineExecuted(2), BoolSet(guest = false) |
| 3 | LineExecuted(3), BoolSet(pass = false) |
| 4 | LineExecuted(4), Evaluated("guest && pass" = false), Evaluated("member || false" = true), BoolSet(ok = true) |
| 5 | LineExecuted(5), Output("True") |

The two `Evaluated` steps show **the order C# really uses**: `guest && pass` first, then `member || ...`.

**Investigate (watch list):** variables `member = true`, `guest = false`, `pass = false`, then the steps `1st: guest && pass = false`, `2nd: member || false = true`.

**Hypotheses ("Why did the member get in?"):**
- A. "pass is true." — Wrong (pass is false).
- B. "|| lets a member in." — Close ("Partly. But why is the pass never checked for a member? Look at which part runs first.").
- C. **"&& runs before ||, so the pass only applies to the guest, not the member."** — Correct.

**Fix options:**
| Option | Change | Quality | Test result |
|---|---|---|---|
| 1 | Change line 4 to: `bool ok = (member \|\| guest) && pass;` | **Best** | Pass: "ok is False: a member with no pass stays out." |
| 2 | Change line 1 to: `bool member = false;` | Symptom-only | Fail: "You changed the visitor, not the rule. A member with no pass would still get in." |
| 3 | Change line 4 to: `bool ok = member \|\| guest \|\| pass;` | Wrong | Fail: "ok is True. Now the pass is not required at all." |

**Test:** `ok == false` for member = true, guest = false, pass = false.
**Debrief:** "&& is evaluated before ||. Use parentheses to say what you mean: (member || guest) && pass. At work: a missing pair of parentheses is a classic permission bug."
**Hints:** (1) "Which part of line 4 runs first?" (2) "&& binds tighter than ||." (3) "Parentheses decide the order."
**Stars:** same rules as before.

## 3. What is new in the engine and the scene (bigger than any Chapter 1 room)
1. **Two new trace events:** `BoolSet(variable, true/false)` and `Evaluated(expression, result)`.
2. **KeepState** keeps a list of variables with their value (including bools) and a list of evaluation steps in order. Watch list reads from them.
3. **A new "Gate" picture in the Keep frame:** rows of text. Top: the variables, e.g. `member = true`. Below: the steps, e.g. `guest && pass -> false`, then `member || false -> true`. The newest row is highlighted. No new art. Guards and chests are hidden in this room.
4. **Scene builder:** add the row texts to the Keep frame, rebuild the Room scene (one Replace click), and check Rooms 1.1 to 1.6 still look the same.
5. `Room21.cs`, `RoomLibrary` gets `"2-1"` (the Keep catalog already lists it), tests.
6. Rooms 1.1 to 1.6 must stay unchanged (all old tests must pass).

## 4. Build phases
- **A. Core:** new events, KeepState variables and steps, Room21, library, tests.
- **B. Scene:** the Gate rows, rebuild scene, play 2.1 from the Keep Map (back up and restore your save), re-check one Chapter 1 room.
- **C. Playtest:** classmate: "Explain why the member got in without a pass."

## 5. Verification
- Rooms 1.1 to 1.6 behave exactly as before.
- 2.1: verdicts for predict, cause, each fix; auto test; Goal text on Ticket and Fix; stars saved to room 2-1.
- Core has no Unity references; no rule logic in UI scripts.

## 6. Risks
- This is the first room whose picture is not guards and chests. If the rows look like plain text, a drawn gate sprite can come later (art).
- `guest && pass` is short, but longer rules in 2.4 (`age >= 60 || isStudent`) will need more rows. The row count is set to 6 for now.
- One test case (member = true) is enough to teach, but real tests use several cases. That is room 2.4's lesson (test 99, 100, 101).

## 7. Questions for you
1. Is the story "member with no pass got in" clear? Local alternative: a student ID or PWD card instead of "pass"; say which you prefer.
2. Show the evaluation as text rows (recommended, no art), or do you want to draw a gate sprite first?
