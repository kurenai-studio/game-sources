# Plan: Room 1.3 "The Shared Inventory"

Status: **PLAN v1 (2026-11-03). Waiting for your check. No code written yet.**
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
Same mechanics as Rooms 1.1 and 1.2. All wording is a draft for you to change.

---

## 1. Why this room
Lesson plan row 1.3 (Bug Hunt): "Two adventurers see each other's loot. A `List<T>` assigned from another variable instead of copied."
Room 1.1 showed sharing with a made-up `Chest` class. 1.3 shows the same rule on a real C# type, `List<string>`, and the real fix: **make a copy**.
At work: "My cart shows another user's items."

## 2. The room
**Ticket:** "The hero's inventory shows a Dagger he never picked up."
**Goal text:** "Hero keeps only the Potion. Rogue keeps only the Dagger."
```csharp
1  var hero = new List<string>();
2  var rogue = hero;
3  hero.Add("Potion");
4  rogue.Add("Dagger");
5  Console.WriteLine(hero.Count);
```
No support-code box (List is built in).

**Predict:** "What does line 5 print?" Options `0`, `1`, `2`, `An error`. Correct: `2`.

**Trace (13 events):**
| Line | Events |
|---|---|
| 1 | LineExecuted(1), VariableDeclared(hero), ObjectCreated(#1, List), ReferenceAssigned(hero → #1) |
| 2 | LineExecuted(2), VariableDeclared(rogue), ReferenceAssigned(rogue → #1) |
| 3 | LineExecuted(3), ObjectMutated(#1, "Potion added") |
| 4 | LineExecuted(4), ObjectMutated(#1, "Dagger added") |
| 5 | LineExecuted(5), Output("2") |

**Investigate (watch list):** `hero -> list #1`, `rogue -> list #1`.

**Hypotheses ("Why does the hero hold a Dagger?"):**
- A. "Line 3 adds the Potion to both lists." — Wrong (there is only one list).
- B. "Line 2 makes a second list." — Close (right line, wrong idea: it only copies the reference).
- C. **"Line 2 gives rogue the same list, so both names use one list."** — Correct.

**Fix options:**
| Option | Change | Quality | Test result |
|---|---|---|---|
| 1 | Line 2 becomes `var rogue = new List<string>(hero);` | **Best** | Pass: "hero holds 1 item and rogue holds 1 item." |
| 2 | Line 5 becomes `Console.WriteLine(1);` | Symptom-only | Fail: "It prints 1, but the Dagger is still in the hero's list. You only hid the problem." |
| 3 | Line 5 becomes `Console.WriteLine(rogue.Count);` | Wrong | Fail: "rogue also holds 2 items. Nothing is separate yet." |

**Test:** `hero.Count == 1` and `rogue.Count == 1`.
**Debrief:** "A List is an object, so `b = a` shares it. To get an independent list, copy it: `new List<string>(a)`. At work: the bug behind 'my cart shows another user's items'."
**Hints:** (1) "How many lists exist after line 2?" (2) "A list variable holds a reference, like the chest in room 1.1." (3) "`new List<string>(x)` builds a separate list with the same items."
**Stars:** same rules as before.

## 3. What changes in the engine
Almost nothing. Small, safe changes:
1. `KeepState` words follow the object's type name instead of always saying "chest": "hero now points to list #1.", "list #1: Potion added.", watch lines "hero -> list #1". For Room 1.1 the type is "Chest", so its text is identical (existing tests must still pass).
2. The Keep view label shows the item count, e.g. "List #1 (2 items)". This also appears in 1.1 ("Chest #1 (1 item)"). **[OPEN]** I recommend keeping it, because the count is the evidence in this room. Say if you want it only for lists.
3. `Room13.cs`, `RoomLibrary` gets `"1-3"`, tests.
4. The Keep Map already lists 1.3 as "The Shared Inventory". Its Enter room button works once the library has it.
**Art:** the list is drawn with the same chest sprite for now (an "inventory chest"). Own art later. No scene rebuild needed.

## 4. Build phases
- **A. Core:** KeepState wording, Room13, library, tests (all old tests + new pass).
- **B. Scene:** view label with item count; play 1.3 from the Keep Map; check 1.1 and 1.2 still look right.
- **C. Playtest:** classmate: "Explain why the hero had a Dagger, and what `new List<string>(hero)` does."

## 5. Verification
- 1.1 and 1.2 behave exactly as before (text unchanged, except the item count on the label).
- 1.3: verdicts for predict, cause, each fix; auto test; Goal text on Ticket and Fix; stars saved to room 1-3.
- No rule logic in UI scripts; Core has no Unity references.

## 6. Risks
- A shallow copy teaches half the story: items inside the copied list are still shared when they are objects. That is Room 1.4 ("Copy of a Copy"). The 1.3 debrief only says "independent list", not "deep copy".
- Item count label may not fit under the chest. Checked in Phase B.

## 7. Questions for you
1. Okay with the Hero / Rogue story and the Potion / Dagger items?
2. Item count on the label for all rooms (recommended), or only lists?
