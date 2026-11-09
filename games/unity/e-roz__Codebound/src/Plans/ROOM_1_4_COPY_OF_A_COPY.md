# Plan: Room 1.4 "Copy of a Copy"

Status: **PLAN v1 (2026-11-03). Waiting for your check. No code written yet.**
Workflow: brainstorm (done) → **plan (this file)** → check → [changes → check again] → code → check against this plan → test.
Same mechanics as Rooms 1.1 to 1.3. All wording is a draft for you to change.

---

## 1. Why this room
Room 1.3 taught: `new List<string>(hero)` gives an independent list. Players may now think "a copy is always safe".
Room 1.4 shows the catch (lesson row 1.4, Repair): the new list is separate, but **the objects inside are still shared** (shallow copy).
At work: config and DTO copies that still share inner objects.

## 2. The room
**Ticket:** "The rogue upgraded his sword to 9 damage, and the hero's sword changed too."
**Goal text:** "Hero's sword stays at 5. Rogue's sword becomes 9."
```csharp
1  var hero = new List<Sword>();
2  hero.Add(new Sword(5));
3  var rogue = new List<Sword>(hero);
4  rogue[0].Damage = 9;
5  Console.WriteLine(hero[0].Damage);
```
No support-code box. (`Sword` has a `Damage` field; the Ticket and debrief say so.) **[OPEN]** or show a small "Sword class" box like 1.1's Chest class. I recommend showing it, so `Damage` is not magic.

**Predict:** "What does line 5 print?" Options `5`, `9`, `14`, `An error`. Correct: `9`.

**Trace (15 events):**
| Line | Events |
|---|---|
| 1 | LineExecuted(1), VariableDeclared(hero), ObjectCreated(#1, List), ReferenceAssigned(hero → #1) |
| 2 | LineExecuted(2), ItemObjectCreated(#2, Sword, Damage 5), ItemAdded(list #1, sword #2) |
| 3 | LineExecuted(3), VariableDeclared(rogue), ListCopied(#3 from #1), ReferenceAssigned(rogue → #3) |
| 4 | LineExecuted(4), FieldSet(sword #2, Damage = 9) |
| 5 | LineExecuted(5), Output("9") |

**Investigate (watch list):** `hero -> list #1`, `rogue -> list #3`, `sword #2: Damage 9 (in list #1 and list #3)`.
The Keep labels read "List #1: Sword #2 (Damage 9)" and "List #3: Sword #2 (Damage 9)". Same "Sword #2" in both is the clue.

**Hypotheses ("Why did the hero's sword change?"):**
- A. "Line 3 makes both names use one list, like in room 1.3." — Wrong (there are two lists now: #1 and #3).
- B. "Line 4 changes the hero's list." — Close (right line, but it changes the Sword, not a list).
- C. **"The two lists are separate, but both hold the same Sword, and line 4 changes that Sword."** — Correct.

**Fix options:**
| Option | Change | Quality | Test result |
|---|---|---|---|
| 1 | Line 4 becomes `rogue[0] = new Sword(9);` | **Best** | Pass: "hero's sword is 5 and rogue's sword is 9." |
| 2 | Line 5 becomes `Console.WriteLine(5);` | Symptom-only | Fail: "It prints 5, but both lists still share one Sword. You only hid the problem." |
| 3 | Line 3 becomes `var rogue = new List<Sword>();` | Wrong | Fail: "Line 4 threw ArgumentOutOfRangeException. The rogue's list is empty." |

**Test:** `hero[0].Damage == 5` and `rogue[0].Damage == 9`.
**Debrief:** "Copying a list copies the list, not the objects inside. Both lists still point to the same Sword. This is a shallow copy. To change one without the other, give the copy its own new object. At work: a copied config that still shares inner objects."
**Hints:** (1) "How many Sword objects exist after line 3?" (2) "`new List<Sword>(hero)` copies the list, not the swords." (3) "Both lists hold a reference to the same Sword."
**Stars:** same rules as before.

## 3. What changes in the engine
This room needs objects **inside** lists, so it is bigger than 1.3 (still Core only + one label change):
1. `TraceEventType` gets five new events: `ItemObjectCreated`, `ItemAdded`, `ListCopied`, `ItemReplaced`, `FieldSet`.
2. `KeepState` remembers item objects (id, type name, field name and value) and which list holds which item. Existing string items for 1.1 to 1.3 keep working.
3. Chest labels show "List #1: Sword #2 (Damage 9)". Watch list also names shared items.
4. `Room14.cs`, `RoomLibrary` gets `"1-4"`, tests. Room 1.1 to 1.3 text stays identical (all old tests must still pass).
5. The Chest class box already exists and is reused for the Sword class.
**Art:** lists use the chest sprite as before. The Sword is not drawn as its own icon, only named in the labels **[OPEN]**: recommended for this slice. A drawn Sword linked to both lists would be clearer but needs scene and art work.
No scene rebuild needed.

## 4. Build phases
- **A. Core:** new events, KeepState item objects, Room14, library, tests.
- **B. Scene:** label text; play 1.4 from the Keep Map; check 1.1, 1.2 and 1.3 still look right.
- **C. Playtest:** classmate: "Explain why the hero's sword changed even though the lists are separate."

## 5. Verification
- Rooms 1.1 to 1.3 behave exactly as before.
- 1.4: verdicts for predict, cause, each fix; auto test; Goal text on Ticket and Fix; stars saved to room 1-4.
- No rule logic in UI scripts; Core has no Unity references.

## 6. Risks
- Biggest engine change so far. Mitigation: Phase A is pure C# with tests first.
- Two lists plus a shared Sword may be hard to see with labels only. Checked in Phase B; if unclear, we add a drawn Sword icon.
- The best fix replaces the element. A full "clone every item" fix is left out because it needs a loop (later chapters).

## 7. Questions for you
1. Show a "Sword class" box (recommended), or leave it out?
2. Sword only in labels for now (recommended), or draw it as its own icon linked to both lists?
